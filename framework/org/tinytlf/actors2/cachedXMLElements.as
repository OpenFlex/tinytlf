package org.tinytlf.actors2
{
	import flash.geom.Rectangle;
	
	import asx.array.pluck;
	import asx.fn._;
	import asx.fn.callProperty;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.tap;
	
	import trxcllnt.ds.RTree;
	
	/**
	 * Mutates a (Rectangle, RTree) into an Array<XML> where each element in
	 * Array<XML> intersects with the viewport Rectangle.
	 * 
	 * @author ptaylor
	 */
	public function cachedXMLElements(viewport:Rectangle, cache:RTree):Array/*<DOMElement>*/ {
		return sequence(
			cache.intersections,
			partial(pluck, _, 'element'),
			tap(callProperty('sortOn', 'index', Array.NUMERIC), _),
			partial(pluck, _, 'node')
		)(viewport);
	}
}


