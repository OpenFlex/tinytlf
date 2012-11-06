package org.tinytlf.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.box.*;
	
	public class MiddleAlignment implements IAlignment
	{
		public function getLineSize(box:Box, previousLine:TextLine):Number
		{
			return box.height - box.paddingTop - box.paddingBottom;
		}
		
		public function getAlignment(box:Box, line:DisplayObject):Number
		{
			return (box.height - line.height) * 0.5;
		}
	}
}