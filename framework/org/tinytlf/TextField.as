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
	import raix.reactive.scheduling.Scheduler;
	
	public class TextField extends Sprite
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super();
			x = xpos;
			y = ypos;
			if(parent) parent.addChild(this);
		}
		
		private var _engine:TextEngine = new TextEngine();
		public function get engine():TextEngine {
			return _engine;
		}
		
		public function set engine(value:TextEngine):void {
			
			if(value == _engine) return;
			
			if(engine) engine.teardown();
			
			_engine = value;
			
			engine.startup();
			
			const onError:Function = function(e:Error):void { trace(e.getStackTrace()); };
			const textField:TextField = this;
			
			const cssObs:IObservable = engine.getInstance(IObservable, 'css');
			cssObs.subscribe(function(css:CSS):void {
				const progression:String = TextBlockProgression.convert(css['progression'] || TextBlockProgression.TTB);
				const containerType:Class = progression == TextBlockProgression.TTB ? VBox : HBox;
				
				if(!(container is containerType)) {
					container.removeChildren();
					if($contains(container)) $removeChild(container);
					$addChild(container = new containerType());
				}
			});
			
			const paragraphs:IObservable = engine.getInstance(IObservable, 'paragraphs') as IObservable;
			paragraphs.subscribe(
				function(paragraph:IObservable):void {
					
					var p:Paragraph;
					
					paragraph.filter(function(p:Paragraph):Boolean {
						return !contains(p);
					}).
					subscribe(
						function(n:Paragraph):void {
							addChild(p = n);
						},
						function():void {
							trace("complete", p.block['cssInheritanceChain']);
						},
						function(e:Error):void {
							trace("error", e);
						}
					);
				},
				removeChildren
			);
			
			engine.width = width;
			engine.height = height;
			engine.css = css;
			engine.html = html;
		}
		
		private var container:DisplayObjectContainer = new Sprite();
		
		public function $addChild(child:DisplayObject):DisplayObject {
			return super.addChild(child);
		}
		
		public function $contains(child:DisplayObject):Boolean {
			return super.contains(child);
		}
		
		public function $removeChild(child:DisplayObject):DisplayObject {
			return super.removeChild(child);
		}
		
		override public function addChild(child:DisplayObject):DisplayObject {
			return container.addChild(child);
		}
		
		override public function contains(child:DisplayObject):Boolean {
			return container.contains(child);
		}
		
		override public function removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void {
			return container.removeChildren(beginIndex, endIndex);
		}
		
		private var _height:Number = int.MAX_VALUE;
		override public function get height():Number {
			return _height;
		}
		
		override public function set height(h:Number):void
		{
			_height = h;
			engine.height = h;
		}
		
		private var _width:Number = TextLine.MAX_LINE_WIDTH;
		override public function get width():Number {
			return _width;
		}
		
		override public function set width(w:Number):void
		{
			_width = w;
			engine.width = w;
		}
		
		private var _html:String = '';
		public function get html():* {
			return _html;
		}
		
		public function set html(value:*):void {
			_html = value;
			engine = new TextEngine();
		}
		
		private var _css:String = '';
		public function get css():String {
			return _css;
		}
		
		public function set css(value:*):void {
			_css = value;
			engine.css = _css;
		}
	}
}