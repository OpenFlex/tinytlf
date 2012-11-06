package org.tinytlf.html
{
	import flash.events.*;
	import flash.text.engine.*;
	
	import org.tinytlf.*;
	
	public interface IDOMNode extends IStyleable
	{
		function getChildAt(index:int):IDOMNode;
		function get numChildren():int;
		function get parentNode():IDOMNode;
		
		function get content():ContentElement;
		function set content(ce:ContentElement):void;
		function get length():int;
		
		function set mirror(eventMirror:*):void;
		
		function get cssInheritanceChain():String;
		function get nodeName():String;
		function get nodeValue():String;
	}
}