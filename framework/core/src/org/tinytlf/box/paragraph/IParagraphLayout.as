package org.tinytlf.box.paragraph
{
	import org.tinytlf.box.alignment.IAlignment;
	import org.tinytlf.box.progression.IProgression;

	public interface IParagraphLayout
	{
		function get progression():IProgression;
		function set progression(value:IProgression):void;
		
		function layout(lines:Array, paragraph:Paragraph):Array/*<TextLine>*/;
	}
}