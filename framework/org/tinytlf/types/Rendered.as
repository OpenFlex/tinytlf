package org.tinytlf.types
{
	import flash.display.DisplayObject;

	public class Rendered
	{
		public function Rendered(element:DOMElement, display:DisplayObject) {
			this['element'] = element;
			this['display'] = display;
		}
		
		public const element:DOMElement;
		public const display:DisplayObject;
	}
}