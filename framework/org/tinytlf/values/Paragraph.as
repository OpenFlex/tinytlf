package org.tinytlf.values
{
	import com.bit101.components.*;
	
	import flash.display.*;
	import flash.events.Event;
	import flash.text.engine.*;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.classes.Container;
	import org.tinytlf.classes.Virtualizer;
	import org.tinytlf.constants.TextAlign;
	import org.tinytlf.constants.TextBlockProgression;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;
	
	public class Paragraph extends Container
	{
		public function set life(value:IObservable):void {
			lifeCancelable.cancel();
			lifeCancelable = value.subscribe(onNextLife, destroy, engine.onError);
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
			a = a.concat();
			
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
				container = new containerType();
			}
			
			container['spacing'] = block['leading'] * block.getStyle('fontMultiplier');
			
			// TODO: HBox alignment
			container['alignment'] = TextAlign.isValid(block['textAlign']) ? block['textAlign'] : TextAlign.LEFT;
			
			$addChild(container);
			removeChildren();
			updateVirtualizer();
			
			lineCancelable = new CompositeCancelable([
				
				// Add the last line's descent to the container height.
				textLines.last().
					subscribe(function(line:TextLine):void {
						container.height += line.descent;
						width = container.width + block['paddingLeft'] + block['paddingRight'];
						height = block['paddingTop'] + container.height + block['paddingBottom'];
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
				textLines.subscribe(addChild, addingLinesComplete),
				
				lines.connect()
			]);
			
			engine.subscriptions.add(lineCancelable);
		}
		
		protected function addingLinesComplete():void {
			width = container.width + block['paddingLeft'] + block['paddingRight'];
			height = block['paddingTop'] + container.height + block['paddingBottom']
			container.y += block['paddingTop'];
			
//			const g:Graphics = graphics;
//			g.clear();
//			g.beginFill(0x00, 0);
//			g.lineStyle(1, 0xcccccc);
//			g.drawRect(0, 0, width, height);
//			g.endFill();
			
			height += block['marginTop'] + block['marginBottom'];
			width += block['marginLeft'] + block['marginRight'];
			
			updateVirtualizer();
			
			// EVERYTHING rides on this event dispatching :/
			dispatchEvent(new Event(Event.RESIZE, true));
		}
		
		protected function updateVirtualizer(...args):void {
			const key:String = node.@cssInheritanceChain.toString();
			const prevKey:String = prev ? prev.node.@cssInheritanceChain.toString() : '';
			
			const index:int = virtualizer.getIndex(key);
			const prevIndex:int = virtualizer.getIndex(prevKey);
			
			if(index > -1) {
				virtualizer.setSize(key, height);
			} else if(prevIndex > -1) {
				virtualizer.addAt(key, prevIndex + 1, height);
			} else {
				virtualizer.add(key, height);
			}
			
			y = virtualizer.getStart(key);
		}
		
		public function destroy():void {
			lifeCancelable.cancel();
			lineCancelable.cancel();
		}
	}
}