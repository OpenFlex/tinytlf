package org.tinytlf.lambdas
{
	import flash.geom.*;
	import flash.text.engine.*;

	/**
	 * @author ptaylor
	 */
	public function getAtomSide(line:TextLine, x:Number, y:Number):int
	{
		const atomIndex:int = line.getAtomIndexAtPoint(x, y);
		
		if(atomIndex < 0) return 0;
		
		const center:Number = line.getAtomCenter(atomIndex);
		const pt:Point = line.localToGlobal(new Point(center));
		
		return pt.x > x ? 0 : 1
	}
}