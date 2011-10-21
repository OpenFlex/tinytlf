package org.tinytlf.layout.rect.sector
{
	import flash.text.engine.*;
	
	import org.tinytlf.layout.alignment.*;
	import org.tinytlf.layout.progression.*;
	import org.tinytlf.util.*;
	
	public class StandardSectorRenderer implements ISectorRenderer
	{
		public function StandardSectorRenderer(aligner:IAlignment = null, progression:IProgression = null)
		{
			a = aligner;
			p = progression;
		}
		
		public function render(block:TextBlock, sector:TextSector, lines:Array = null):Array /*<TextLine>*/
		{
			lines ||= [];
			
			if(TextBlockUtil.isInvalid(block))
			{
				lines = lines.concat(createLines(
									 block,
									 TextBlockUtil.getFirstValidLineBeforeInvalidLine(block),
									 sector));
			}
			
			return lines.concat();
		}
		
		protected function createLines(block:TextBlock, pLine:TextLine, sector:TextSector):Array /*<TextLine>*/
		{
			const lines:Array = [];
			
			var line:TextLine = pLine;
			
			while(true)
			{
				line = createTextLine(block, line, p.getLineSize(sector, line));
				
				if(line == null)
					break;
				
				lines.push(line);
			}
			
			return lines;
		}
		
		protected function createTextLine(block:TextBlock, previousLine:TextLine, width:Number):TextLine
		{
			const orphan:TextLine = TextLineUtil.checkOut();
			return orphan ?
				block.recreateTextLine(orphan, previousLine, width, 0.0, true) :
				block.createTextLine(previousLine, width, 0.0, true);
		}
		
		protected var a:IAlignment;
		public function set alignment(value:IAlignment):void
		{
			a = value;
		}
		
		protected var p:IProgression;
		public function get progression():IProgression
		{
			return p;
		}
		
		public function set progression(value:IProgression):void
		{
			p = value;
		}
	}
}
