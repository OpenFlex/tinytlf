package org.tinytlf.views.layout
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.observables.Values;

	/**
	 * @author ptaylor
	 */
	public function sizeBlockChild(parent:Values, child:Values):Values {
		
		const w:Number = parent.width;
		const h:Number = parent.height;
		
		const pw:Number = child.percentWidth;
		const ph:Number = child.percentHeight;
		
		const cw:Number = child.explicitWidth;
		const ch:Number = child.explicitHeight;
		
		child.width = pw != pw ? (cw || w) : pw * w * .01;
		
		if(ph == ph)
			child.height = ph * h * .01;
		else if(ch == ch)
			child.height = ch;
		
		child.viewport = new Rectangle(0, 0, child.width, child.height || h);
		
		return child;
	}
}