package org.tinytlf.values
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	
	import raix.reactive.*;

	public class Block
	{
		public function Block(block:TextBlock, node:XML = null, element:ContentElement = null, styles:Styleable = null)
		{
			block.userData = this;
			this['node'] = node;
			this['element'] = element;
			this['block'] = block;
			this['styles'] = styles;
		}
		
		public var prev:Block;
		public var next:Block;
		
		public const node:XML;
		public const element:ContentElement;
		public const block:TextBlock;
		public const styles:Styleable;
	}
}