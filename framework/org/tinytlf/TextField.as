package org.tinytlf
{
	import com.bit101.components.*;
	
	import flash.display.*;
	
	import org.tinytlf.actions.KeyboardActions;
	import org.tinytlf.actions.CursorActions;
	import org.tinytlf.classes.CSS;
	import org.tinytlf.classes.Container;
	import org.tinytlf.constants.TextBlockProgression;
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.*;

	public class TextField extends Container
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super(parent, xpos, ypos);
			TextEngine.stage ||= parent ? parent.stage : null;
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
			
			const textField:TextField = this;
			
			const cssObs:IObservable = engine.getInstance(IObservable, 'css');
			const paragraphs:IObservable = engine.getInstance(IObservable, 'paragraphs') as IObservable;
			const caretSubj:ISubject = engine.getInstance(ISubject, 'caret') as ISubject;
			
			engine.subscriptions.add(
				// Recreate the layout container when the CSS changes if need be.
				cssObs.subscribe(onNextCSS, null, onError)
			);
			
			engine.subscriptions.add(
				// Add paragraphs
				paragraphs.subscribe(onNextParagraph, removeChildren, onError)
			);
			
			new KeyboardActions(engine, this);
			new CursorActions(engine, this);
			
			engine.width = width;
			engine.height = height;
			engine.css = css;
			engine.html = html;
		}
		
		private const caret:Sprite = new Sprite();
		
		override public function set height(h:Number):void {
			super.height = h;
			engine.height = h;
		}
		
		override public function set width(w:Number):void {
			super.width = w;
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
		
		private function onError(e:Error):void {
			trace(e.getStackTrace());
		}
		
		private function onNextCSS(css:CSS):void {
			const progression:String = TextBlockProgression.convert(css['progression'] || TextBlockProgression.TTB);
			const containerType:Class = progression == TextBlockProgression.TTB ? VBox : HBox;
			
			if(!(container is containerType)) {
				container.removeChildren();
				if($contains(container)) $removeChild(container);
				$addChild(container = new containerType());
				container['spacing'] = css.getStyle('paragraphSpacing');
			}
		}
		
		private function onNextParagraph(life:IObservable):void {
			var p:Paragraph;
			engine.subscriptions.add(life.filter(function(p:Paragraph):Boolean {
					return !contains(p);
				}).
				subscribe(
					function(n:Paragraph):void {
						addChild(p = n);
					},
					function():void {
						trace("complete", p.block['cssInheritanceChain']);
					},
					onError)
			);
		}
	}
}