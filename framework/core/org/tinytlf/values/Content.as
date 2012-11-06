package org.tinytlf.values
{
	import flash.text.engine.*;

	public class Content
	{
		public function Content(node:XML, element:ContentElement)
		{
			this['node'] = node;
			this['element'] = element;
		}
		
		public const node:XML;
		public const element:ContentElement;
	}
}