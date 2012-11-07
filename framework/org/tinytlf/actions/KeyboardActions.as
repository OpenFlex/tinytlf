package org.tinytlf.actions
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.engine.*;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.TextField;
	import org.tinytlf.events.keyboard.arrowdown;
	import org.tinytlf.events.keyboard.arrowleft;
	import org.tinytlf.events.keyboard.arrowright;
	import org.tinytlf.events.keyboard.arrowup;
	import org.tinytlf.events.modifiers.option;
	import org.tinytlf.events.modifiers.shift;
	import org.tinytlf.events.mouse.down;
	import org.tinytlf.events.stahp;
	import org.tinytlf.lambdas.getIndexAtPoint;
	import org.tinytlf.lambdas.nextWordBoundary;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Line;
	import org.tinytlf.values.Paragraph;
	import org.tinytlf.values.Selection;
	
	import raix.reactive.*;

	public class KeyboardActions
	{
		public function KeyboardActions(engine:TextEngine, textField:TextField)
		{
			engine.subscriptions.add(engine.caret.subscribe(onNextCaret));
			engine.subscriptions.add(Observable.timer(0, 350).subscribe(onNextCaretBlink));
			
			const caretSubj:ISubject = engine.getInstance(ISubject, 'caret');
			const selectionSubj:ISubject = engine.getInstance(ISubject, 'selection');
			
			const clickInLine:IObservable = down(textField).filter(targetIsTextLine).
				peek(stahp).publish().refCount();
			
			const clickInParagraph:IObservable = down(textField).filter(targetIsParagraph).
				peek(stahp).publish().refCount();
			
			const shiftOptionArrowLeft:IObservable = shift(option(arrowleft(textField))).
				peek(stahp).publish().refCount();
			
			const shiftOptionArrowRight:IObservable = shift(option(arrowright(textField))).
				peek(stahp).publish().refCount();
			
			const shiftOptionArrowUp:IObservable = shift(option(arrowup(textField))).
				peek(stahp).publish().refCount();
			
			const shiftOptionArrowDown:IObservable = shift(option(arrowdown(textField))).
				peek(stahp).publish().refCount();
			
			const optionArrowLeft:IObservable = option(arrowleft(textField)).
				peek(stahp).publish().refCount();
			
			const optionArrowRight:IObservable = option(arrowright(textField)).
				peek(stahp).publish().refCount();
			
			const optionArrowUp:IObservable = option(arrowup(textField)).
				peek(stahp).publish().refCount();
			
			const optionArrowDown:IObservable = option(arrowdown(textField)).
				peek(stahp).publish().refCount();
			
			const shiftArrowLeft:IObservable = shift(arrowleft(textField)).
				peek(stahp).publish().refCount();
			
			const shiftArrowRight:IObservable = shift(arrowright(textField)).
				peek(stahp).publish().refCount();
			
			const shiftArrowUp:IObservable = shift(arrowup(textField)).
				peek(stahp).publish().refCount();
			
			const shiftArrowDown:IObservable = shift(arrowdown(textField)).
				peek(stahp).publish().refCount();
			
			const arrowLeft:IObservable = arrowleft(textField).publish().refCount();
			const arrowRight:IObservable = arrowright(textField).publish().refCount();
			const arrowUp:IObservable = arrowup(textField).publish().refCount();
			const arrowDown:IObservable = arrowdown(textField).publish().refCount();
			
			// Any time any of these happen, clear selections.
			engine.subscriptions.add(Observable.merge([
					clickInLine, clickInParagraph,
					optionArrowLeft, optionArrowRight,
					optionArrowUp, optionArrowDown,
					arrowLeft, arrowRight,
					arrowUp, arrowDown
				]).
				subscribe(function(...args):void {
					selectionSubj.onNext(new Selection(null, null));
				}));
			
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
			
			// Move the caret left by word boundary
			engine.subscriptions.add(
				shiftOptionArrowLeft.merge(optionArrowLeft).
					mapMany(combineSubjectAndSelector(caretSubj, mapWordLeft)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret left by word boundary
			engine.subscriptions.add(
				shiftOptionArrowRight.merge(optionArrowRight).
					mapMany(combineSubjectAndSelector(caretSubj, mapWordRight)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret to the beginning of the paragraph
			engine.subscriptions.add(
				shiftOptionArrowUp.merge(optionArrowUp).
					mapMany(combineSubjectAndSelector(caretSubj, mapParagraphUp)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret to the end of the paragraph
			engine.subscriptions.add(
				shiftOptionArrowDown.merge(optionArrowDown).
					mapMany(combineSubjectAndSelector(caretSubj, mapParagraphDown)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret one left
			engine.subscriptions.add(
				shiftArrowLeft.merge(arrowLeft).
					mapMany(combineSubjectAndSelector(caretSubj, mapOneLeft)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret one right
			engine.subscriptions.add(
				shiftArrowRight.merge(arrowRight).
					mapMany(combineSubjectAndSelector(caretSubj, mapOneRight)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret one line up
			engine.subscriptions.add(
				shiftArrowUp.merge(arrowUp).
					mapMany(combineSubjectAndSelector(caretSubj, mapOneUp)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
			
			// Move the caret one line down
			engine.subscriptions.add(
				shiftArrowDown.merge(arrowDown).
					mapMany(combineSubjectAndSelector(caretSubj, mapOneDown)).
					repeat().
					subscribe(caretSubj.onNext, null, engine.onError));
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
			line.stage.focus = line;
			
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
		
		private function mapWordLeft(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			var textLine:TextLine = caret.line.line;
			
			if(index > 0) {
				return caret.setValues([nextWordBoundary(textLine, index - 1)]);
			}
			
			return mapOneLeft(caret);
		}
		
		private function mapWordRight(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			const textLine:TextLine = caret.line.line;
			
			if(index < textLine.atomCount) {
				return caret.setValues([nextWordBoundary(textLine, index, false)]);
			}
			
			return mapOneRight(caret);
		}
		
		private function mapParagraphUp(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			
			if(index > 0) {
				const paragraph:Paragraph = caret.paragraph;
				const textLine:TextLine = paragraph.getChildAt(0) as TextLine;
				return caret.setValues([0, textLine.userData]);
			}
			
			return mapOneLeft(caret);
		}
		
		private function mapParagraphDown(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			var textLine:TextLine = caret.line.line;
			
			if(index < textLine.atomCount) {
				const paragraph:Paragraph = caret.paragraph;
				textLine = paragraph.getChildAt(paragraph.numChildren - 1) as TextLine;
				return caret.setValues([textLine.atomCount, textLine.userData]);
			}
			
			return mapOneRight(caret);
		}
		
		private function mapOneLeft(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			
			if(index > 0) {
				return caret.setValues([index - 1]);
			}
			
			const line:Line = caret.line.prev;
			if(line) return caret.setValues([line, line.line.atomCount]);
			
			const paragraph:Paragraph = caret.paragraph.prev;
			if(paragraph == null) return caret;
			
			const textLine:TextLine = paragraph.getChildAt(paragraph.numChildren - 1) as TextLine;
			return caret.setValues([paragraph, paragraph.block, textLine.userData, textLine.atomCount, paragraph.node]);
		}
		
		private function mapOneRight(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			var textLine:TextLine = caret.line.line;
			
			if(index < textLine.atomCount) {
				return caret.setValues([index + 1]);
			}
			
			const line:Line = caret.line.next;
			if(line) return caret.setValues([line, 0]);
			
			const paragraph:Paragraph = caret.paragraph.next;
			if(paragraph == null) return caret;
			
			textLine = paragraph.getChildAt(0) as TextLine;
			return caret.setValues([paragraph, paragraph.block, textLine.userData, 0, paragraph.node]);
		}
		
		private function mapOneUp(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			var line:Line = caret.line.prev;
			
			if(line == null) {
				const paragraph:Paragraph = caret.paragraph.prev;
				
				if(paragraph == null) return caret.setValues([0]);
				
				line = (paragraph.getChildAt(paragraph.numChildren - 1) as TextLine).userData;
			}
			
			const textLine:TextLine = caret.line.line;
			const bounds:Rectangle = index >= textLine.atomCount ?
				textLine.getAtomBounds(textLine.atomCount - 1) :
				textLine.getAtomBounds(index);
			
			const newTextLine:TextLine = line.line;
			const newLineStageCoords:Point = newTextLine.localToGlobal(bounds.topLeft);
			const newIndex:int = index == 0 ?
				0 :
				newTextLine.getAtomIndexAtPoint(newLineStageCoords.x + (bounds.width * 0.5), newLineStageCoords.y);
			
			if(newIndex != -1) {
				return caret.setValues([line.paragraph, line.block, line, newIndex, line.block.node]);
			}
			
			if(bounds.left > newTextLine.width) {
				return caret.setValues([line.paragraph, line.block, line, newTextLine.atomCount, line.block.node]);
			}
			
			return caret.setValues([line.paragraph, line.block, line, 0, line.block.node]);
		}
		
		private function mapOneDown(caret:Caret, ...args):Caret {
			const index:int = caret.index;
			var line:Line = caret.line.next;
			var textLine:TextLine;
			
			if(line == null) {
				var paragraph:Paragraph = caret.paragraph.next;
				
				if(paragraph == null) {
					paragraph = caret.paragraph;
					textLine = paragraph.getChildAt(paragraph.numChildren - 1) as TextLine;
					return caret.setValues([textLine.atomCount]);
				}
				
				line = (paragraph.getChildAt(0) as TextLine).userData;
			}
			
			textLine = caret.line.line;
			const bounds:Rectangle = index >= textLine.atomCount ?
				textLine.getAtomBounds(textLine.atomCount - 1) :
				textLine.getAtomBounds(index);
			
			const newTextLine:TextLine = line.line;
			const newLineStageCoords:Point = newTextLine.localToGlobal(bounds.topLeft);
			const newIndex:int = index == 0 ?
				0 :
				newTextLine.getAtomIndexAtPoint(newLineStageCoords.x + (bounds.width * 0.5), newLineStageCoords.y);
			
			if(newIndex != -1) {
				return caret.setValues([line.paragraph, line.block, line, newIndex, line.block.node]);
			}
			
			if(bounds.left > newTextLine.width) {
				return caret.setValues([line.paragraph, line.block, line, newTextLine.atomCount, line.block.node]);
			}
			
			return caret.setValues([line.paragraph, line.block, line, 0, line.block.node]);
		}
	}
}