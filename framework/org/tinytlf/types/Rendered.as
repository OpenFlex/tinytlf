package org.tinytlf.types
{
	import flash.display.DisplayObject;

	public class Rendered
	{
		public function Rendered(node:XML, display:DisplayObject) {
			this['node'] = node;
			this['display'] = display;
		}
		
		public const node:XML;
		public const display:DisplayObject;
	}
}