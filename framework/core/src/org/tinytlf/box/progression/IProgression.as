package org.tinytlf.box.progression
{
	import flash.display.DisplayObject;
	import flash.text.engine.*;
	
	import org.tinytlf.box.alignment.IAlignment;
	import org.tinytlf.box.*;
	
	public interface IProgression
	{
		function get alignment():IAlignment;
		function set alignment(value:IAlignment):void;
		
		function getLineSize(box:Box, previousLine:TextLine):Number;
		
		function position(box:Box, child:DisplayObject):void;
		
		function getTotalHorizontalSize(box:Box):Number;
		
		function getTotalVerticalSize(box:Box):Number;
	}
}