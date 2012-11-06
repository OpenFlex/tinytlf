package org.tinytlf.values
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;

	public class Content extends Styleable
	{
		public function Content(node:XML, element:ContentElement, styles:Styleable)
		{
			super(styles);
			
			this['node'] = node;
			this['element'] = element;
		}
		
		public const node:XML;
		public const element:ContentElement;
	}
}