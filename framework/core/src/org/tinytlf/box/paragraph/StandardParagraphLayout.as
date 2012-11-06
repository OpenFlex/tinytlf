package org.tinytlf.box.paragraph
{
	import flash.text.engine.*;
	
	import org.tinytlf.box.alignment.*;
	import org.tinytlf.box.progression.*;
	
	public class StandardParagraphLayout implements IParagraphLayout
	{
		public function StandardParagraphLayout(progression:IProgression = null)
		{
			p = progression;
		}
		
		public function layout(lines:Array, paragraph:Paragraph):Array /*<TextLine>*/
		{
			lines.forEach(function(line:TextLine, ... args):void {
				p.position(paragraph, line);
			});
			
			return lines.concat();
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
