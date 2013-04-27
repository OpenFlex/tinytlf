package org.tinytlf.enumerables
{
	import asx.array.pluck;
	
	import flash.geom.Rectangle;
	
	import trxcllnt.ds.HRTree;
	
	/**
	 * Mutates a (Rectangle, RTree) into an Array<DOMELement> where each element in
	 * Array<DOMElement> intersects with the viewport Rectangle.
	 * 
	 * @author ptaylor
	 */
	public function cachedValues(cache:HRTree, area:Rectangle):Array/*<Values>*/ {
		const cached:Array = pluck(cache.search(area), 'description');
		cached.sortOn('index', Array.NUMERIC);
		return cached;
	}
}



