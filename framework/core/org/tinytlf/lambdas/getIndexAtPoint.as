package org.tinytlf.lambdas
{
	import flash.geom.*;
	import flash.text.engine.*;

	/**
	 * @author ptaylor
	 */
	public function getIndexAtPoint(line:TextLine, x:Number, y:Number):int
	{
		if(!line) return -1;
		
		const index:int = line.getAtomIndexAtPoint(x, y);
		
		if(index < 0)
		{
			const bounds:Rectangle = line.getBounds(line.stage);
			const center:Point = bounds.topLeft.clone();
			center.offset(bounds.width * .5, bounds.height * .5);
			
			if(y < bounds.y)
				return 0;
			if(y > bounds.y && y < bounds.y + bounds.height)
				return line.atomCount;
			
			return (x < center.x) ? 0 : line.atomCount;
		}
		
		return Math.max(index + getAtomSide(line, x, y), 0);
	}
}