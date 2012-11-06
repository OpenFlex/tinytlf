package org.tinytlf.box.paragraph
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.engine.*;
	import flash.utils.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.*;
	import org.tinytlf.box.*;
	import org.tinytlf.box.alignment.*;
	import org.tinytlf.box.progression.*;
	import org.tinytlf.content.*;
	import org.tinytlf.html.*;
	import org.tinytlf.layout.*;
	import org.tinytlf.util.*;
	
	public class Paragraph extends Box
	{
		[Inject]
		public var cefm:IContentElementFactoryMap;
		
		public function Paragraph()
		{
			super();
			
			renderer.progression = layout.progression = progression;
		}
		
		override public function dispose():void
		{
			invalidate();
			
			kids.length = 0;
			
			if(!block)
				return;
			
			if(block.firstLine)
				block.releaseLines(block.firstLine, block.lastLine);
			
			block.releaseLineCreationData();
			
			TextBlockUtil.checkIn(block);
			block = null;
		}
		
		private var block:TextBlock;
		
		override protected function internalParse():Array
		{
			if(block)
				TextBlockUtil.checkIn(block);
			
			if(!domNode)
				return super.internalParse()
			
			injectInto(domNode, true);
			
			if(domNode.content == null)
			{
				domNode.content = cefm.instantiate(domNode.nodeName).create(domNode);
			}
			
			block = TextBlockUtil.checkOut();
			block.content = domNode.content;
			
			block.lineRotation = domNode.getStyle('lineRotation') || TextRotation.ROTATE_0;
			
			return super.internalParse();
		}
		
		override public function invalidate():void
		{
			kids.forEach(function(line:TextLine, ... args):void {
				TextLineUtil.checkIn(TextLineUtil.cleanLine(line));
			});
			super.invalidate();
		}
		
		override public function render():Array
		{
			if(block && (invalid || TextBlockUtil.isInvalid(block)))
			{
				th = 0;
				tw = 0;
				
				setupBlockJustifier(block);
				
				renderer.progression.alignment =
					layout.progression.alignment = getAlignmentForProgression(textAlign, blockProgression);
				
				block.lineRotation = blockProgression == TextBlockProgression.TTB ?
					TextRotation.ROTATE_0 : blockProgression == TextBlockProgression.LTR ?
					TextRotation.ROTATE_270 :
					TextRotation.ROTATE_90;
				
				block.bidiLevel = direction == TextDirection.LTR ? 0 : 1;
				
				kids.forEach(function(line:TextLine, ... args):void {
					if(line.parent)line.parent.removeChild(line);
				});
				kids.length = 0;
				
				// Do the magic.
				kids.push.apply(null, layout.layout(renderer.render(block, this, TextBlockUtil.getValidLines(block)), this)
								.map(function(line:TextLine, ... args):TextLine {
									line.x += x;
									line.y += y;
									return line;
								}));
				
				tw = progression.getTotalHorizontalSize(this);
				th = progression.getTotalVerticalSize(this);
			}
			
			invalid = false;
			
			return children;
		}
		
		override public function getSelectionRects(start:int, end:int):Array
		{
			if(!block)
				return [];
			
			const boxes:Array = [];
			const blockLength:int = block.lastLine.textBlockBeginIndex + block.lastLine.atomCount;
			
			start = Math.max(0, Math.min(blockLength - 1, start));
			end = Math.max(0, Math.min(blockLength - 1, end));
			
			var line:TextLine = block.getTextLineAtCharIndex(start);
			const lastLine:TextLine = block.getTextLineAtCharIndex(end);
			
			while(line)
			{
				const s:int = start - line.textBlockBeginIndex;
				const e:int = Math.min(end - line.textBlockBeginIndex, line.atomCount);
				
				if(s < 0)
					break;
				
				boxes.push(line.getAtomBounds(s).union(line.getAtomBounds(e)));
				line = line == lastLine ? null : line.nextLine;
			}
			
			return boxes;
		}
		
		override public function set progression(p:IProgression):void
		{
			super.progression = p;
			
			renderer.progression =
				layout.progression = p;
		}
		
		private var _layout:IParagraphLayout = new StandardParagraphLayout();
		public function get layout():IParagraphLayout
		{
			return _layout;
		}
		
		public function set layout(value:IParagraphLayout):void
		{
			if(value == _layout)
				return;
			
			_layout = value;
			layout.progression = progression;
			invalidate();
		}
		
		private var _renderer:IParagraphRenderer = new StandardParagraphRenderer();
		public function get renderer():IParagraphRenderer
		{
			return _renderer;
		}
		
		public function set renderer(value:IParagraphRenderer):void
		{
			if(value == _renderer)
				return;
			
			_renderer = value;
			renderer.progression = progression;
			invalidate();
		}
		
		override public function set x(value:Number):void
		{
			if(value == xValue)
				return;
			
			kids.forEach(function(line:TextLine, ... args):void {
				line.x += (value - x);
			});
			
			xValue = value;
		}
		
		override public function set y(value:Number):void
		{
			if(value == yValue)
				return;
			
			kids.forEach(function(line:TextLine, ... args):void {
				line.y += (value - y);
			});
			
			yValue = value;
		}
		
		/*
		 * Paragraph linked list impl.
		 */
		private var prev:Paragraph;
		public function get previousParagraph():Paragraph
		{
			return prev;
		}
		
		public function set previousParagraph(value:Paragraph):void
		{
			if(value == prev)
				return;
			
			prev = value;
		}
		
		private var next:Paragraph;
		
		public function get nextParagraph():Paragraph
		{
			return next;
		}
		
		public function set nextParagraph(value:Paragraph):void
		{
			if(next == value)
				return;
			
			next = value;
		}
		
		/*
		 * Formatting properties.
		 */
		
		private var direction:String = TextDirection.LTR;
		public function get textDirection():String
		{
			return direction;
		}
		
		public function set textDirection(value:String):void
		{
			if(!TextDirection.isValid(value))
				value = TextDirection.LTR;
			
			if(value == direction)
				return;
			
			direction = value;
			invalidate();
		}
		
		private var localeValue:String = 'en';
		public function get locale():String
		{
			return localeValue;
		}
		
		public function set locale(value:String):void
		{
			if(value == localeValue)
				return;
			
			localeValue = value;
			invalidate();
		}
		
		private var indent:Number = 0;
		public function get textIndent():Number
		{
			return indent;
		}
		
		public function set textIndent(value:Number):void
		{
			if(value == indent)
				return;
			
			indent = value;
			invalidate();
		}
		
		private function setupBlockJustifier(block:TextBlock):void
		{
			const justification:String = textAlign == TextAlign.JUSTIFY ?
				LineJustification.ALL_BUT_LAST : LineJustification.UNJUSTIFIED;
			
			const justifier:TextJustifier = TextJustifier.getJustifierForLocale(locale);
			justifier.lineJustification = justification;
			
			if(!block.textJustifier ||
				block.textJustifier.lineJustification != justification ||
				block.textJustifier.locale != locale)
			{
				applyTo(justifier);
				block.textJustifier = justifier;
			}
		}
	}
}
