package org.tinytlf.values
{
	import flash.display.*;
	import flash.text.engine.*;
	
	public class Caret
	{
		public function Caret(paragraph:Paragraph, block:Block, line:Line, index:int, node:XML)
		{
			this['block'] = block;
			this['node'] = node;
			this['index'] = index;
			this['line'] = line;
			this['paragraph'] = paragraph;
		}
		
		public const block:Block;
		public const index:int;
		public const line:Line;
		public const node:XML;
		public const paragraph:Paragraph;
	}
}