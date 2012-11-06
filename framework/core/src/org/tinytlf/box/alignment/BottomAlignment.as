package org.tinytlf.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.box.*;
	import org.tinytlf.box.paragraph.*;
	
	public class BottomAlignment extends Alignment implements IAlignment
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			return box.height - box.paddingTop - box.paddingBottom - getIndent(box, previousLine);
		}
		
		public function getAlignment(box:Box, line:DisplayObject):Number
		{
			return box.height - line.height - box.paddingBottom - getIndent(box, line);
		}
	}
}
