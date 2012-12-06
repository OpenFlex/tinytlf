package org.tinytlf.actions
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.TextField;
	import org.tinytlf.lambdas.concatParams;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.*;

	public class CaretActions
	{
		public function CaretActions(engine:TextEngine, textField:TextField)
		{
			const caret:IObservable = engine.caret;
			const height:IObservable = engine.height;
			const vScroll:IObservable = engine.vScroll;
			
			engine.subscriptions.add(Observable.timer(0, 350).subscribe(onNextCaretBlink));
			engine.subscriptions.add(caret.subscribe(onNextCaret));
			engine.subscriptions.add(caret.mapMany(
					combineSubjectAndSelector(
						height.combineLatest(vScroll.take(1), concatParams), 
						mapCaretVScroll)
				).
				subscribe(engine.setVScroll, null, engine.onError));
		}
		
		private const caret:Sprite = new Sprite();
		
		private function onNextCaretBlink(val:int):void {
			caret.visible = val % 2 == 0;
		}
		
		private function onNextCaret(value:Caret):void {
			const index:int = value.index;
			
			if(index == -1) {
				if(caret.parent)
					caret.parent.removeChild(caret);
				
				return;
			}
			
			caret.visible = true;
			
			const line:TextLine = value.line.line;
			if(line.stage) line.stage.focus = line;
			
			const x:Number = index >= line.atomCount ?
				line.getAtomBounds(line.atomCount - 1).right :
				line.getAtomBounds(index).left; 
			
			caret.x = x;
			caret.y = -line.ascent;
			
			line.addChild(caret);
			
			const g:Graphics = caret.graphics;
			g.clear();
			g.beginFill(0x00);
			g.drawRect(0, 0, 1, line.textHeight);
			g.endFill();
		}
		
		private function combineSubjectAndSelector(subj:IObservable, selector:Function):Function {
			return function(n:*):IObservable {
				return subj.take(1).map(function(s:*):* {
					return selector(s, n);
				});
			};
		}
		
		private function mapCaretVScroll(heightAndScroll:Array, caret:Caret):Number {
			const paragraph:Paragraph = caret.paragraph;
			
			const height:Number = heightAndScroll[0];
			const vScroll:Number = heightAndScroll[1];
			
			if(!paragraph) return vScroll;
			
			if(paragraph.y < vScroll || paragraph.y + paragraph.height > vScroll + height)
				return vScroll + paragraph.height;
			
			return vScroll;
		}
	}
}