package org.tinytlf.values
{
	import com.bit101.components.*;
	
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.classes.Container;
	import org.tinytlf.classes.Virtualizer;
	import org.tinytlf.constants.TextBlockProgression;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;
	
	public class Paragraph extends Container
	{
		public function set life(value:IObservable):void {
			lifeCancelable.cancel();
			lifeCancelable = value.subscribe(onNextLife, destroy, error);
		}
		
		[Inject]
		public var virtualizer:Virtualizer;
		
		[Inject]
		public var engine:TextEngine;
		
		private var _block:Block;
		public function get block():Block {
			return _block;
		}
		
		private var _node:XML;
		public function get node():XML {
			return _node;
		}
		
		public var prev:Paragraph;
		public var next:Paragraph;
		
		protected var lifeCancelable:ICancelable = Cancelable.empty;
		protected var lineCancelable:ICancelable = Cancelable.empty;
		
		protected function onNextLife(a:Array):void {
			
			const paragraph:Paragraph = this;
			
			const lines:IConnectableObservable = a.pop().publish();
			const textLines:IObservable = lines.map(function(line:Line):TextLine {
				line.paragraph = paragraph;
				return line.line;
			});
			
			width = a.pop();
			_block = a.pop();
			_node = block.node;
			
			lineCancelable.cancel();
			
			const progression:String = TextBlockProgression.convert(block['textDirection'] || TextBlockProgression.TTB);
			const containerType:Class = progression == TextBlockProgression.TTB ? VBox : HBox;
			if(!(container is containerType)) {
				$removeChild(container);
				removeChildren();
				$addChild(container = new containerType());
				container['spacing'] = block['leading'];
			}
			container.removeChildren();
			
			lineCancelable = new CompositeCancelable([
				
				// Add the last line's descent to the container height.
				textLines.last().
					subscribe(function(line:TextLine):void {
						container.height += line.descent;
					}),
				
				// Adjust the container's Y by the first line's ascent
				textLines.first().
					subscribe(function(line:TextLine):void {
						container.y = line.ascent;
						container.x = block['paddingLeft'];
					}),
				
				// Add all the line children
				// When the lines finish rendering, update the Virtualizer
				// with our new width and height values.
				textLines.subscribe(addChild, updateVirtualizer),
				
				lines.connect()
			]);
			
			engine.subscriptions.add(lineCancelable);
		}
		
		protected function updateVirtualizer():void {
			width = container.width + block['paddingLeft'] + block['paddingRight'];
			height = block['paddingTop'] + container.height + block['paddingBottom']
			container.y += block['paddingTop'];
			
			const g:Graphics = graphics;
			g.clear();
			g.beginFill(0x00, 0);
			g.lineStyle(1, 0xcccccc);
			g.drawRect(0, 0, width, height);
			g.endFill();
			
			height += block['marginTop'] + block['marginBottom'];
			width += block['marginLeft'] + block['marginRight'];
			
			const node:XML = block.content.node;
			const index:int = virtualizer.getIndex(node);
			
			if(index == -1) {
				virtualizer.add(node, height); // TODO: make this work with horizontal progressions too.
			} else {
				virtualizer.setSizeAt(index, height);
			}
		}
		
		public function destroy():void {
			lifeCancelable.cancel();
			lineCancelable.cancel();
			
			if(container) container.removeChildren();
			if(parent) parent.removeChild(this);
		}
		
		protected function error(e:Error):void {
			trace(e);
		}
	}
}