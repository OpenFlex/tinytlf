package org.tinytlf.layout.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.layout.box.*;
	import org.tinytlf.layout.box.paragraph.*;
	
	public class LeftAlignment extends Alignment implements IAlignment
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			return box.width - box.paddingLeft - box.paddingRight  - getIndent(box, previousLine);
		}
		
		public function getAlignment(box:Box, line:DisplayObject):Number
		{
			return getIndent(box, line) + box.paddingLeft;
		}
	}
}
