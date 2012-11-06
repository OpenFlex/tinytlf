package org.tinytlf.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.box.*;
	import org.tinytlf.box.paragraph.*;
	
	public class RightAlignment extends Alignment implements IAlignment
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			return box.width - box.paddingLeft - box.paddingRight - getIndent(box, previousLine);
		}
		
		public function getAlignment(box:Box, line:DisplayObject):Number
		{
			return box.width - line.width - box.paddingRight - getIndent(box, line);
		}
	}
}
