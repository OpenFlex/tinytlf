package org.tinytlf.values
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;

	public class Content
	{
		public function Content(node:XML, element:ContentElement, styles:Styleable)
		{
			this['node'] = node;
			this['element'] = element;
			this['styles'] = styles;
		}
		
		public const node:XML;
		public const element:ContentElement;
		public const styles:Styleable;
	}
}