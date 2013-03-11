package org.tinytlf.values
{
	import flash.text.engine.ContentElement;
	
	import org.tinytlf.classes.Styleable;

	public class Content extends Styleable
	{
		public function Content(node:XML, element:ContentElement, styles:Styleable)
		{
			super(styles);
			
			this['node'] = node;
		}
		
		public const node:XML;
		public const element:ContentElement;
	}
}