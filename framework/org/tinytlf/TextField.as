package org.tinytlf
{
	import com.bit101.components.*;
	
	import flash.display.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.constants.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.IObservable;
	
	public class TextField extends Component
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super(parent, xpos, ypos);
			
			const paragraphs:IObservable = engine.getInstance(IObservable, 'paragraphs') as IObservable;
			const css:CSS = engine.getInstance(CSS);
			
			const progression:String = TextBlockProgression.convert(css['progression'] || TextBlockProgression.TTB);
			super.addChild(container = progression == TextBlockProgression.TTB ? new VBox() : new HBox());
			
			paragraphs.subscribe(
				addChild,
				removeChildren,
				function(e:Error):void {
					trace(e.getStackTrace());
				}
			);
		}
		
		private var container:DisplayObjectContainer = new Sprite();
		
		override public function addChild(child:DisplayObject):DisplayObject {
			return container.addChild(child);
		}
		
		override public function removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void {
			return container.removeChildren(beginIndex, endIndex);
		}
		
		public const engine:TextEngine = new TextEngine();
		
		override public function set height(h:Number):void
		{
			super.height = engine.height = h;
		}
		
		override public function set width(w:Number):void
		{
			super.width = engine.width = w;
		}
		
		public function set html(value:*):void {
			engine.html = value;
		}
	}
}