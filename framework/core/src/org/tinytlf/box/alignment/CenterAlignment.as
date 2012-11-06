package org.tinytlf.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.box.*;
	
	public class CenterAlignment implements IAlignment
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			return box.width - box.paddingLeft - box.paddingRight;
		}
		
		public function getAlignment(box:Box, line:DisplayObject):Number
		{
			return (box.width - line.width) * 0.5;
		}
	}
}