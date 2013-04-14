package org.tinytlf.views
{
	import asx.array.filter;
	import asx.array.reduce;
	import asx.object.isA;
	
	import flash.text.engine.TextLine;
	
	import org.tinytlf.types.Region;

	public class Paragraph extends Box
	{
		public function Paragraph(region:Region)
		{
			super(region);
		}
		
		public function get lines():Array {
			return filter(children, isA(TextLine));
		}
		
		override protected function draw():void {
			
			const lineHeight:Number = reduce(0, lines, function(y:Number, line:TextLine):Number {
				line.y = y + line.ascent;
				return line.y + line.descent;
			}) as Number;
			
			height = lineHeight;
			
			graphics.clear();
			graphics.lineStyle(2, 0xFF0000, 0.25);
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
			
			super.draw();
		}
	}
}