package org.tinytlf.values
{
	import com.bit101.components.*;
	
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.constants.*;
	
	import raix.reactive.*;
	
	public class Paragraph extends Component
	{
		public function set life(value:IObservable):void {
			lifeCancelable.cancel();
			lifeCancelable = value.subscribe(onNextLife, destroy, error);
		}
		
		[Inject]
		public var virtualizer:Virtualizer;
		
		private var _block:Block;
		public function get block():Block {
			return _block;
		}
		
		public var prev:Paragraph;
		public var next:Paragraph;
		
		protected var container:DisplayObjectContainer = new Sprite();
		protected var lifeCancelable:ICancelable = Cancelable.empty;
		protected var lineCancelable:ICancelable = Cancelable.empty;
		
		protected function onNextLife(a:Array):void {
			
			const paragraph:Paragraph = this;
			
			const lines:IObservable = a.pop();
			const textLines:IObservable = lines.
				peek(function(line:Line):void {
					line.paragraph = paragraph;
				}).
				map(function(line:Line):TextLine {
					return line.line;
				});
			
			width = a.pop();
			_block = a.pop();
			
			lineCancelable.cancel();
			
			const progression:String = TextBlockProgression.convert(block['textDirection'] || TextBlockProgression.TTB);
			const containerType:Class = progression == TextBlockProgression.TTB ? VBox : HBox;
			if(!(container is containerType)) {
				removeChildren();
				container = new containerType(this);
			}
			container.removeChildren();
			
			lineCancelable = new CompositeCancelable([
				// Adjust the container's Y by the first line's ascent
				textLines.first().
					subscribe(function(line:TextLine):void {
						container.y = line.ascent;
						container.x = block['paddingLeft'];
					}),
				
				// Add all the line children
				// When the lines finish rendering, update the Virtualizer
				// with our new width and height values.
				textLines.subscribe(container.addChild, updateVirtualizer)
			]);
		}
		
		protected function updateVirtualizer():void {
			width = container.width + block['paddingLeft'] + block['paddingRight'];
			height = block['paddingTop'] + container.height + block['paddingBottom'];
			container.y += block['paddingTop'];
			
			const g:Graphics = graphics;
			g.clear();
			g.lineStyle(1, 0xcccccc);
			g.drawRect(0, 0, width, height);
			g.endFill();
			
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