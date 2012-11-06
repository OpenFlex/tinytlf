package org.tinytlf.box.alignment
{
	import flash.display.*;
	import flash.text.engine.*;
	
	import org.tinytlf.box.*;
	import org.tinytlf.box.paragraph.*;

	internal class Alignment
	{
		protected function getIndent(box:Box, child:DisplayObject):Number
		{
			if(!(box is Paragraph))
				return 0;
			
			if(!child)
				box['textIndent'];
			
			if(!(child is TextLine))
				return 0;
			
			return (child as TextLine).previousLine ? 0 : box['textIndent'];
		}
	}
}