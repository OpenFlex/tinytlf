package org.tinytlf.actions
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.TextField;
	import org.tinytlf.events.keyboard.left;
	import org.tinytlf.events.keyboard.right;
	import org.tinytlf.events.mouse.down;
	import org.tinytlf.events.stop;
	import org.tinytlf.lambdas.getIndexAtPoint;
	import org.tinytlf.values.Block;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Line;
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;

	public class CaretActions
	{
		public function CaretActions(engine:TextEngine, textField:TextField)
		{
			engine.subscriptions.add(engine.caret.subscribe(onNextCaret));
			engine.subscriptions.add(Observable.timer(0, 350).subscribe(onNextCaretBlink));
			
			const caretSubj:ISubject = engine.getInstance(ISubject, 'caret');
			
			// Handle clicks inside TextLines
			engine.subscriptions.add(
				down(textField).
					filter(targetIsTextLine).
					peek(stop).
					map(mapLineClick).
					zip(caretSubj, mapCaret).
					subscribe(caretSubj.onNext)
			);
			
//			// Handle clicks inside paragraphs
			engine.subscriptions.add(
				down(textField).
					filter(targetIsParagraph).
					peek(stop).
					map(mapParagraphClick).
					zip(caretSubj, mapCaret).
					subscribe(caretSubj.onNext)
			);
			
			// Move the caret left when the user hits left
			engine.subscriptions.add(
				left(textField).
					mapMany(function(k:KeyboardEvent):IObservable {
						return caretSubj.take(1).zip(Observable.value(k), mapOneLeft);
					}).
					repeat().
					subscribe(caretSubj.onNext)
			);
			
			// Move the caret right when the user hits left
			engine.subscriptions.add(
				right(textField).
					mapMany(function(k:KeyboardEvent):IObservable {
						return caretSubj.take(1).zip(Observable.value(k), mapOneRight);
					}).
					repeat().
					subscribe(caretSubj.onNext)
			);
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
			
			const x:Number = index == line.atomCount ?
				line.getAtomBounds(index - 1).right :
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
		
		private function mapCaret(values:Array, caret:Caret):Caret {
			return caret.setValues(values);
		}
		
		private function mapLineClick(event:MouseEvent):Array/*<Line, int>*/ {
			const textLine:TextLine = event.target as TextLine;
			const index:int = getIndexAtPoint(textLine, event.stageX, event.stageY);
			const line:Line = textLine.userData as Line;
			
			return [line.paragraph, line.block, line, index, line.block.node];
		}
		
		private function mapParagraphClick(event:MouseEvent):Array/*<Line, int>*/ {
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
			
			return [line.paragraph, line.block, line, index, line.block.node];
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
		
//		private function mapParagraphCaret(event:MouseEvent):Caret {
//			const target:DisplayObjectContainer = event.target as DisplayObjectContainer;
//			const x:Number = event.stageX;
//			const y:Number = event.stageY;
//			const bounds:Rectangle = target.getBounds(target.stage);
//			
//			var textLine:TextLine;
//			var index:int;
//			
//			if(y < (bounds.y + (bounds.height * 0.5))) {
//				textLine = target.getChildAt(0) as TextLine;
//				index = 0
//			} else {
//				textLine = target.getChildAt(target.numChildren - 1) as TextLine;
//				index = textLine.atomCount;
//			}
//			
//			const line:Line = textLine.userData as Line;
//			const block:Block = line.block;
//			const paragraph:Paragraph = line.paragraph;
//			
//			return new Caret(paragraph, block, line, index, block.content.node); 
//		}
		
//		private function mapCaretLeft(event:KeyboardEvent, caret:Caret):Caret {
//			const index:int = caret.index;
//			const line:Line = caret.line;
//			
//			if(index > 0) {
//				return new Caret(caret.paragraph, caret.block, line, index - 1, caret.node);
//			}
//			else if(line.prev) {
//				index = line.prev.atomCount - 1;
//				line = line.prev;
//			}
//			
//			return new Caret(data.block, data.container, data.node, index, line);
//		}
	}
}