package org.tinytlf
{
	import com.bit101.components.ScrollBar;
	import com.bit101.components.VScrollBar;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import org.tinytlf.actions.CaretActions;
	import org.tinytlf.actions.CursorActions;
	import org.tinytlf.actions.KeyboardActions;
	import org.tinytlf.classes.Container;

	public class TextField extends Container
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super(parent, xpos, ypos);
			
			$addChild(scrollBar = new VScrollBar(null, 0, 0, function(...args):void {
				engine.vScroll = scrollBar.value;
			}));
		}
		
		private var _engine:TextEngine = new TextEngine();
		private var totalHeight:Number = 0;
		private var scrollBar:ScrollBar;
		
		public function get engine():TextEngine {
			return _engine;
		}
		
		public function set engine(value:TextEngine):void {
			
			if(value == _engine) return;
			
			if(engine) engine.stop();
			
			_engine = value;
			totalHeight = 0;
			
			engine.start(stage);
			
//			const textField:TextField = this;
			
//			const virtualizer:Virtualizer = engine.getInstance(Virtualizer);
			
//			engine.subscriptions.add(
				// Recreate the layout container when the CSS changes if need be.
//				engine.css.subscribe(onNextCSS, null, engine.onError));
			
//			engine.subscriptions.add(
				// Add paragraphs
//				paragraphs.subscribe(onNextParagraph, removeChildren, engine.onError));
			
			// update the scrollRect
//			engine.subscriptions.add(
//				engine.width.combineLatest(engine.height, concatParams).
//				combineLatest(engine.vScroll, concatParams).
//				combineLatest(engine.hScroll, concatParams).
//				combineLatest(engine.css, identity).
//				combineLatest(Observable.fromEvent(this, Event.RESIZE).peek(stahp), identity).
//				subscribe(function(a:Array):void {
//					a = a.concat();
//					
//					const hs:Number = a.pop();
//					const vs:Number = a.pop();
//					const h:Number = a.pop();
//					const w:Number = a.pop();
//					
//					if(virtualizer.size > h && !$contains(scrollBar)) {
//						scrollBar.visible = true;
//					} else if(virtualizer.size < h && $contains(scrollBar)) {
//						scrollBar.visible = false;
//					}
//					
//					scrollBar.x = w;
//					scrollBar.y = 0;
//					scrollBar.height = h;
//					scrollBar.maximum = virtualizer.size - h;
//					scrollBar.setThumbPercent(h / virtualizer.size);
//					scrollBar.lineSize = h / 20;
//					scrollBar.pageSize = h / 10;
//					
//					adjustChildren();
//					
//					container.scrollRect = new Rectangle(hs - 1, vs - 1, w + 2, h + 2);
//				}));
			
			engine.width = width;
			engine.height = height;
			engine.css = css;
			engine.html = html;
			
			new KeyboardActions(engine, this);
			new CursorActions(engine, this);
			new CaretActions(engine, this);
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
		
		private var _html:* = '';
		public function get html():* {
			return _html;
		}
		
		public function set html(value:*):void {
			_html = value;
			engine = new TextEngine();
		}
		
		private var _css:* = '';
		public function get css():* {
			return _css;
		}
		
		public function set css(value:*):void {
			_css = value;
			engine.css = _css;
		}
		
//		private function onNextCSS(css:CSS):void {
//			const virtualizer:Virtualizer = engine.getInstance(Virtualizer);
//			virtualizer.gap = css.getStyle('paragraphSpacing') * css.getStyle('fontMultiplier');
//		}
//		
//		private function onNextParagraph(life:IObservable):void {
//			
//			const field:TextField = this;
//			var p:Paragraph;
//			const onNext:Function = function(n:Paragraph):void { addChild(p = n); };
//			const onComplete:Function = function():void { if(p && contains(p)) removeChild(p); }
//				
//			engine.subscriptions.add(life.subscribe(onNext, onComplete, engine.onError));
//		}
//		
//		private function adjustChildren():void {
//			const virtualizer:Virtualizer = engine.getInstance(Virtualizer);
//			for(var i:int = -1; ++i < numChildren;) {
//				const p:Paragraph = getChildAt(i) as Paragraph;
//				p.y = virtualizer.getStart(p.node.@cssInheritanceChain.toString());
//			}
//		}
	}
}