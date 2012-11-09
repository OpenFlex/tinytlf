package org.tinytlf.actions
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.engine.*;
	import flash.ui.*;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.TextField;
	import org.tinytlf.events.mouse.down;
	import org.tinytlf.events.mouse.out;
	import org.tinytlf.events.mouse.over;
	import org.tinytlf.events.stahp;
	import org.tinytlf.lambdas.getIndexAtPoint;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Line;
	import org.tinytlf.values.Paragraph;
	import org.tinytlf.values.Selection;
	
	import raix.reactive.*;

	public class CursorActions
	{
		public function CursorActions(engine:TextEngine, textField:TextField)
		{
			const caretSubj:ISubject = engine.getInstance(ISubject, 'caret');
			const selectionSubj:ISubject = engine.getInstance(ISubject, 'selection');
			
			const clickInLine:IObservable = down(textField).filter(targetIsTextLine).
//				peek(stahp).
				publish().refCount();
			
			const clickInParagraph:IObservable = down(textField).filter(targetIsParagraph).
//				peek(stahp).
				publish().refCount();
			
			engine.subscriptions.add(Observable.merge([
					clickInLine, clickInParagraph
				]).
				subscribe(function(...args):void{
					selectionSubj.onNext(new Selection(null, null));
				}));
			
			engine.subscriptions.add(
				over(textField).subscribe(onNextOver));
			
			engine.subscriptions.add(
				out(textField).subscribe(onNextOut));
			
			// Handle clicks inside TextLines
			engine.subscriptions.add(
				clickInLine.
				mapMany(combineSubjectAndSelector(caretSubj, mapLineClick)).
				repeat().
				subscribe(caretSubj.onNext, null, engine.onError));
			
			// Handle clicks inside paragraphs
			engine.subscriptions.add(
				clickInParagraph.
				mapMany(combineSubjectAndSelector(caretSubj, mapParagraphClick)).
				repeat().
				subscribe(caretSubj.onNext, null, engine.onError));
		}
			
		private function onNextOver(...args):void {
			Mouse.cursor = MouseCursor.IBEAM;
		}
		
		private function onNextOut(...args):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		private function targetIsTextLine(event:MouseEvent):Boolean {
			return event.target is TextLine;
		}
		
		private function targetIsParagraph(event:MouseEvent):Boolean {
			return event.target is Paragraph || event.target.parent is Paragraph;
		}
		
		private function mapLineClick(caret:Caret, event:MouseEvent):Caret/*<Line, int>*/ {
			const textLine:TextLine = event.target as TextLine;
			const index:int = getIndexAtPoint(textLine, event.stageX, event.stageY);
			const line:Line = textLine.userData as Line;
			
			return caret.setValues([line.paragraph, line.block, line, index, line.block.node]);
		}
		
		private function mapParagraphClick(caret:Caret, event:MouseEvent):Caret {
			const x:Number = event.stageX;
			const y:Number = event.stageY;
			const container:DisplayObjectContainer = event.target as DisplayObjectContainer;
			const bounds:Rectangle = container.getBounds(container.stage);
			var index:int, textLine:TextLine;
			
			if(y < bounds.y + (bounds.height * 0.5)) {
				textLine = container.getChildAt(0) as TextLine;
				index = 0;
			} else {
				textLine = container.getChildAt(container.numChildren - 1) as TextLine;
				index = textLine.atomCount;
			}
			
			const line:Line = textLine.userData;
			
			return caret.setValues([line.paragraph, line.block, line, index, line.block.node]);
		}
		
		private function combineSubjectAndSelector(subj:ISubject, selector:Function):Function{
			return function(n:*):IObservable {
				return subj.take(1).map(function(s:*):* {
					return selector(s, n);
				});
			};
		}
	}
}