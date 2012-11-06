package org.tinytlf
{
	import com.bit101.components.*;
	
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.constants.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.IObservable;
	
	public class TextField extends Sprite
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super();
			x = xpos;
			y = ypos;
			if(parent) parent.addChild(this);
			
			const onError:Function = function(e:Error):void { trace(e.getStackTrace()); };
			
			const textField:TextField = this;
			
			const css:IObservable = engine.getInstance(IObservable, 'css');
			css.subscribe(function(css:CSS):void {
				const progression:String = TextBlockProgression.convert(css['progression'] || TextBlockProgression.TTB);
				const containerType:Class = progression == TextBlockProgression.TTB ? VBox : HBox;
				
				if(!(container is containerType)) {
					container.removeChildren();
					$addChild(container = new containerType(textField));
				}
			});
			
			const paragraphs:IObservable = engine.getInstance(IObservable, 'paragraphs') as IObservable;
			paragraphs.subscribe(
				function(paragraph:IObservable):void {
					paragraph.take(1).subscribe(addChild, identity, onError);
				},
				removeChildren,
				onError
			);
			
			engine.width = width;
			engine.height = height;
			
			engine.startup();
		}
		
		public const engine:TextEngine = new TextEngine();
		
		private var container:DisplayObjectContainer = new Sprite();
		
		public function $addChild(child:DisplayObject):DisplayObject {
			return super.addChild(child);
		}
		
		override public function addChild(child:DisplayObject):DisplayObject {
			return container.addChild(child);
		}
		
		override public function removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void {
			return container.removeChildren(beginIndex, endIndex);
		}
		
		private var _height:Number = int.MAX_VALUE;
		override public function set height(h:Number):void
		{
			engine.height = _height = h;
		}
		
		private var _width:Number = TextLine.MAX_LINE_WIDTH;
		override public function set width(w:Number):void
		{
			engine.width = _width = w;
		}
		
		private var _html:* = '';
		public function get html():* {
			return _html;
		}
		
		public function set html(value:*):void {
			engine.html = _html = value;
		}
		
		private var _css:String = '';
		public function get css():String {
			return _css;
		}
		
		public function set css(value:*):void {
			engine.css = _css = value;
		}
	}
}