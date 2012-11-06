package org.tinytlf.box.progression
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.layout.*;
	import org.tinytlf.box.alignment.*;
	import org.tinytlf.box.*;
	import org.tinytlf.box.paragraph.*;
	
	public class TTBProgression implements IProgression
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			const indent:Number = ((!previousLine && box is Box) ? box['textIndent'] : 0) || 0;
			
			return box.textAlign == TextAlign.JUSTIFY ?
				box.width - box.paddingLeft - box.paddingRight - indent :
				a.getLineSize(box, previousLine);
		}
		
		public function position(box:Box, child:DisplayObject):void
		{
			if(child is TextLine)
			{
				positionLine(box, child as TextLine);
				return;
			}
			
			child.y = box.y;
			child.x = box.textAlign == TextAlign.JUSTIFY ?
				defaultAlignment.getAlignment(box, child) :
				a.getAlignment(box, child);
		}
		
		protected function positionLine(box:Box, line:TextLine):void
		{
			const pline:TextLine = line.previousLine;
			
			if(pline)
				line.y = (pline.y + pline.descent + box.leading + line.ascent) || 0;
			else
				line.y = box.paddingTop + line.ascent;
			
			line.x = box.textAlign == TextAlign.JUSTIFY ?
				defaultAlignment.getAlignment(box, line) :
				a.getAlignment(box, line);
		}
		
		public function getTotalHorizontalSize(box:Box):Number
		{
			var w:Number = 0;
			box.
				children.
				forEach(function(line:TextLine, ... args):void {
					w = Math.max(w, line.width);
				});
			return box.paddingLeft + w + box.paddingRight || 0;
		}
		
		public function getTotalVerticalSize(box:Box):Number
		{
			var h:Number = box.paddingTop;
			box.
				children.
				forEach(function(line:TextLine, i:int, a:Array):void {
					h += line.totalHeight;
					
					if(i < a.length - 1)
						h += box.leading;
				});
			
			return h + box.paddingBottom || 0;
		}
		
		protected var a:IAlignment = new LeftAlignment();
		public function get alignment():IAlignment
		{
			return a;
		}
		
		public function set alignment(value:IAlignment):void
		{
			a = value;
		}
		
		protected var defaultAlignment:IAlignment = new LeftAlignment();
	}
}
