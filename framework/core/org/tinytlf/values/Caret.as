package org.tinytlf.values
{
	import flash.display.*;
	import flash.text.engine.*;
	
	public class Caret
	{
		public function Caret(block:TextBlock, container:DisplayObjectContainer, node:XML, index:int, line:TextLine)
		{
			this['block'] = block;
			this['container'] = container;
			this['node'] = node;
			this['index'] = index;
			this['line'] = line;
		}
		
		public const block:TextBlock;
		public const container:DisplayObjectContainer;
		public const node:XML;
		public const index:int;
		public const line:TextLine;
	}
}