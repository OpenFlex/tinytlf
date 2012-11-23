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
	import org.tinytlf.events.keyboard.backspace;
	import org.tinytlf.events.modifiers.option;
	import org.tinytlf.events.modifiers.shift;
	import org.tinytlf.events.stahp;
	import org.tinytlf.lambdas.getLeafAtIndex;
	import org.tinytlf.lambdas.identity;
	import org.tinytlf.lambdas.nextWordBoundary;
	import org.tinytlf.lambdas.setLeafAtIndex;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Line;
	import org.tinytlf.values.Paragraph;
	import org.tinytlf.values.Selection;
	
	import raix.reactive.*;

	public class KeyboardActions
	{
		public function KeyboardActions(engine:TextEngine, textField:TextField)
		{
			const caretSubj:ISubject = engine.getInstance(ISubject, 'caret');
			const selectionSubj:ISubject = engine.getInstance(ISubject, 'selection');
			const xmlNodesSubj:ISubject = engine.getInstance(ISubject, 'xml');
			
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
			
			const back:IObservable = backspace(textField).publish().refCount();
			const arrowLeft:IObservable = arrowleft(textField).publish().refCount();
			const arrowRight:IObservable = arrowright(textField).publish().refCount();
			const arrowUp:IObservable = arrowup(textField).publish().refCount();
			const arrowDown:IObservable = arrowdown(textField).publish().refCount();
			
			// Move the selection one left
//			engine.subscriptions.add(
//				shiftArrowLeft.
//					mapMany(combineSubjectAndSelector(selectionSubj, mapSelectOneLeft)).
//					repeat().
//					subscribe(selectionSubj.onNext, null, engine.onError));
			
//			engine.subscriptions.add(
//				back.
//					mapMany(combineSubjectAndSelector(caretSubj, mapOneBackspace)).
//					repeat().
//					subscribe(xmlNodesSubj.onNext, null, engine.onError));
			
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
				Observable.merge([shiftArrowLeft, arrowLeft, back]).
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
			
			// And finally, any time any of these happen, clear selections.
			engine.subscriptions.add(Observable.merge([
				optionArrowLeft, optionArrowRight,
				optionArrowUp, optionArrowDown,
				arrowLeft, arrowRight,
				arrowUp, arrowDown
			]).
				mapMany(combineSubjectAndSelector(caretSubj, identity)).
				repeat().
				subscribe(function(caret:Caret, ...args):void {
					selectionSubj.onNext(new Selection(caret.setValues([]), caret.setValues([])));
			}));
		}
		
		private function combineSubjectAndSelector(subj:ISubject, selector:Function):Function{
			return function(n:*):IObservable {
				return subj.take(1).map(function(s:*):* {
					return selector(s, n);
				});
			};
		}
		
		private function mapSelectOneLeft(selection:Selection, ...args):Selection {
			return selection.setA(mapOneLeft(selection.a));
		}
		
		private function mapSelectOneRight(selection:Selection, ...args):Selection {
			return selection.setB(mapOneRight(selection.b));
		}
		
		private function mapOneBackspace(caret:Caret, ...args):XML {
			const node:XML = caret.node;
			const info:Array = getLeafAtIndex(node, caret.line.line.textBlockBeginIndex + caret.index);
			const index:int = info.pop();
			const leaf:String = info.pop().toString();
			const result:String = leaf.substring(0, index - 1) + leaf.substring(index);
			
			return setLeafAtIndex(node, result, caret.index).normalize();
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