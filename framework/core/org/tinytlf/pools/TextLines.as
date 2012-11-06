package org.tinytlf.pools
{
	import flash.text.engine.*;
	import flash.utils.*;
	
	public final class TextLines
	{
		public static function cleanLine(line:TextLine):TextLine
		{
			if(line.parent)
				line.parent.removeChild(line);
			
			line.userData = null;
			
			return line;
		}
		
		private static const lines:Dictionary = new Dictionary(false);
		public static var numLines:int = 0;
		
		public static function checkIn(line:TextLine):void
		{
			if(line in lines)
				return;
			
			++numLines;
			lines[cleanLine(line)] = true;
		}
		
		public static function checkOut():TextLine
		{
			for(var line:* in lines)
			{
				delete lines[line];
				--numLines;
				return line;
			}
			
			return null;
		}
	}
}
