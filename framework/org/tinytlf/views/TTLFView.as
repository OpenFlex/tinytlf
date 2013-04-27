package org.tinytlf.views
{
	import org.tinytlf.observables.Values;

	public interface TTLFView
	{
		function get x():Number;
		function set x(val:Number):void
		
		function get y():Number;
		function set y(val:Number):void
		
		function get width():Number;
		function set width(val:Number):void
		
		function get height():Number;
		function set height(val:Number):void
		
		function get element():Values;
	}
}