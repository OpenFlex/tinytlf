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
		
		public const paragraph:Paragraph;
		public const block:Block;
		public const line:Line;
		public const index:int;
		public const node:XML;
		
		public function clone(...newValues):Caret {
			var b:Block, i:int = NaN, l:Line, n:XML, p:Paragraph;
			
			newValues.forEach(function(val:*, ...args):void {
				b ||= val as Block;
				i ||= val as int;
				l ||= val as Line;
				n ||= val as XML;
				p ||= val as Paragraph;
			});
			
			return new Caret(p || paragraph, b || block, l || line, i != i ? index : i, n || node);
		}
	}
}