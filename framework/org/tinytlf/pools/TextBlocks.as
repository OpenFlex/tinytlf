package org.tinytlf.pools
{
	import flash.text.engine.*;
	
	public final class TextBlocks
	{
		public static function cleanBlock(block:TextBlock):TextBlock
		{
			if(!block)
				return block;
			
			if(block.firstLine)
				block.releaseLines(block.firstLine, block.lastLine);
			
			block.releaseLineCreationData();
			block.content = null;
			block.userData = null;
			return block;
		}
		
		private static const blocks:Vector.<TextBlock> = new <TextBlock>[];
		public static function checkIn(block:TextBlock):void
		{
			if(!block)
				return;
			
			blocks.push(cleanBlock(block));
		}
		
		public static function checkOut():TextBlock
		{
			return blocks.pop() || new TextBlock();
		}
	}
}
