package org.tinytlf.values
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	
	import raix.reactive.*;

	public class Block extends Styleable
	{
		public function Block(block:TextBlock, content:Content)
		{
			super(content);
			
			block.userData = this;
			this['block'] = block;
			this['content'] = content;
		}
		
		public var prev:Block;
		public var next:Block;
		public var paragraph:Paragraph;
		
		public const block:TextBlock;
		public const content:Content;
	}
}