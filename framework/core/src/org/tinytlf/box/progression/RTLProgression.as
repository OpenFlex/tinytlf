package org.tinytlf.box.progression
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.layout.*;
	import org.tinytlf.box.alignment.*;
	import org.tinytlf.box.*;
	import org.tinytlf.box.paragraph.*;
	
	public class RTLProgression implements IProgression
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			const indent:Number = ((!previousLine && box is Box) ? box['textIndent'] : 0) || 0;
			
			return box.textAlign == TextAlign.JUSTIFY ?
				box.height - box.paddingTop - box.paddingBottom - indent :
				a.getLineSize(box, previousLine);
		}
		
		public function position(box:Box, child:DisplayObject):void
		{
			if(child is TextLine)
			{
				positionLine(box, child as TextLine);
				return;
			}
			
			child.x = box.x + (box.width - child.width);
			child.y = box.textAlign == TextAlign.JUSTIFY ?
				defaultAlignment.getAlignment(box, child) :
				a.getAlignment(box, child);
		}
		
		protected function positionLine(box:Box, line:TextLine):void
		{
			const pline:TextLine = line.previousLine;
			
			if(pline)
				line.x = pline.x - box.leading - line.width;
			else
				line.x = -box.paddingRight - line.width;
			
			line.y = box.textAlign == TextAlign.JUSTIFY ?
				defaultAlignment.getAlignment(box, line) :
				a.getAlignment(box, line);
		}
		
		public function getTotalHorizontalSize(box:Box):Number
		{
			var w:Number = box.paddingLeft;
			
			box.
				children.
				forEach(function(line:TextLine, i:int, a:Array):void {
					w += line.width;
					
					if(i < a.length - 1)
						w += box.leading;
				});
			
			return w + box.paddingRight;
		}
		
		public function getTotalVerticalSize(box:Box):Number
		{
			var h:Number = 0;
			box.
				children.
				forEach(function(line:TextLine, ... args):void {
					h = Math.max(h, line.height);
				});
			return box.paddingTop + h + box.paddingBottom;
		}
		
		protected var a:IAlignment = new TopAlignment();
		public function get alignment():IAlignment
		{
			return a;
		}
		
		public function set alignment(value:IAlignment):void
		{
			a = value;
		}
		
		protected var defaultAlignment:IAlignment = new TopAlignment();
	}
}
