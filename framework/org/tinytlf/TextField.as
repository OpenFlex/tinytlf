package org.tinytlf
{
	import com.bit101.components.*;
	
	import flash.display.*;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.constants.*;
	import org.tinytlf.events.mouse.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;
	
	public class TextField extends Sprite
	{
		public function TextField(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super();
			x = xpos;
			y = ypos;
			if(parent) {
				parent.addChild(this);
				TextEngine.stage ||= parent.stage;
			}
		}
		
		private var _engine:TextEngine = new TextEngine();
		private var subscriptions:ICancelable = Cancelable.empty;
		
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
			
			subscriptions = new CompositeCancelable([
				
				// Recreate the layout container when the CSS changes if need be.
				cssObs.subscribe(onNextCSS, null, onError),
				
				// Add paragraphs
				paragraphs.subscribe(onNextParagraph, removeChildren, onError),
				
				// Blink the caret
				Observable.timer(0, 350).subscribe(onNextCaretBlink),
				
				// Place the caret
				caretSubj.subscribe(onNextCaretValue),
				
				// Handle clicks inside TextLines
				down(this).filter(onTextLine).map(mapLineCaret).subscribe(caretSubj.onNext)
			]);
			
			engine.width = width;
			engine.height = height;
			engine.css = css;
			engine.html = html;
		}
		
		private var container:DisplayObjectContainer = new Sprite();
		private const caret:Sprite = new Sprite();
		
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
		
		override public function set height(h:Number):void {
			_height = h;
			engine.height = h;
		}
		
		private var _width:Number = TextLine.MAX_LINE_WIDTH;
		override public function get width():Number {
			return _width;
		}
		
		override public function set width(w:Number):void {
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
			}
		}
		
		private function onNextParagraph(life:IObservable):void {
			var p:Paragraph;
			life.filter(function(p:Paragraph):Boolean {
				return !contains(p);
			}).
			subscribe(
				function(n:Paragraph):void { addChild(p = n); },
				function():void { trace("complete", p.block['cssInheritanceChain']); },
				onError
			);
		}
		
		private function onNextCaretBlink(val:int):void {
			caret.visible = val % 2 == 0;
		}
		
		private function onNextCaretValue(value:Caret):void {
			caret.visible = true;
			
			const line:TextLine = value.line.line;
			stage.focus = line;
			
			const index:int = value.index;
			
			const atomBounds:Rectangle = index == line.atomCount ?
				new Rectangle(line.width - caret.width) :
				line.getAtomBounds(index); 
			
			const g:Graphics = caret.graphics;
			g.clear();
			g.beginFill(0x00);
			g.drawRect(0, 0, 1.5, line.textHeight);
			g.endFill();
			
			caret.x = atomBounds.left;
			caret.y = -line.ascent;
			
			line.addChild(caret);
		}
		
		private function onTextLine(event:MouseEvent):Boolean {
			return event.target is TextLine;
		}
		
		private function mapLineCaret(event:MouseEvent):Caret {
			const textLine:TextLine = event.target as TextLine;
			const index:int = getIndexAtPoint(textLine, event.stageX, event.stageY);
			const line:Line = textLine.userData as Line;
			const block:Block = line.block;
			const paragraph:Paragraph = line.paragraph;
			
			return new Caret(paragraph, block, line, index, block.content.node); 
		}
	}
}