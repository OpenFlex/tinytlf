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
		
		private var _block:Block;
		public function get block():Block {
			return _block;
		}
		
		public var prev:Paragraph;
		public var next:Paragraph;
		
		protected var container:Component;
		protected var lifeCancelable:ICancelable = Cancelable.empty;
		protected var lineCancelable:ICancelable = Cancelable.empty;
		
		protected function onNextLife(a:Array):void {
			
			const lines:IObservable = a.pop();
			const textLines:IObservable = lines.map(function(line:Line):TextLine {
				return line.line;
			});
			
			width = a.pop();
			_block = a.pop();
			
			lineCancelable.cancel();
			
			const progression:String = TextBlockProgression.convert(block.styles['progression'] || TextBlockProgression.TTB);
			removeChildren();
			addChild(container = progression == TextBlockProgression.TTB ? new VBox() : new HBox());
			
			lineCancelable = new CompositeCancelable([
				// Adjust the container's Y by the first line's ascent
				textLines.first().
					subscribe(function(line:TextLine):void {
						container.y = line.ascent;
					}),
				
				// Add all the line children
				textLines.
					// When the lines finish rendering, update the Virtualizer
					// with our new width and height values.
					finallyAction(updateVirtualizer).
					subscribe(container.addChild)
			]);
		}
		
		[Inject]
		public var virtualizer:Virtualizer;
		
		protected function updateVirtualizer():void {
			width = container.width;
			height = container.height + container.y;
			
			const node:XML = block.node;
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