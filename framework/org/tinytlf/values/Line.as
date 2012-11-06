package org.tinytlf.values
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;

	public class Line
	{
		public function Line(line:TextLine, block:Block)
		{
			line.userData = this;
			this['block'] = block;
			this['line'] = line;
		}
		
		public var prev:Line;
		public var next:Line;
		public var paragraph:Paragraph;
		
		public const block:Block;
		public const line:TextLine;
	}
}
