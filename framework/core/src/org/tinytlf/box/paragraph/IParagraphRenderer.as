package org.tinytlf.box.paragraph
{
	import flash.text.engine.*;
	
	import org.tinytlf.box.alignment.IAlignment;
	import org.tinytlf.box.progression.IProgression;
	
	public interface IParagraphRenderer
	{
		function get progression():IProgression;
		function set progression(value:IProgression):void;
		
		function render(block:TextBlock, paragraph:Paragraph, existingLines:Array = null):Array/*<TextLine>*/;
	}
}