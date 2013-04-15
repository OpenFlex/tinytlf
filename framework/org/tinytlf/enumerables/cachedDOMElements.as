package org.tinytlf.enumerables
{
	import asx.fn._;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.sequence;
	import asx.fn.tap;
	
	import flash.geom.Rectangle;
	
	import trxcllnt.vr.Virtualizer;
	
	/**
	 * Mutates a (Rectangle, RTree) into an Array<DOMELement> where each element in
	 * Array<DOMElement> intersects with the viewport Rectangle.
	 * 
	 * @author ptaylor
	 */
	public function cachedDOMElements(viewport:Rectangle, cache:Virtualizer):Array/*<DOMElement>*/ {
		return sequence(
			distribute(cache.slice),
//			partial(pluck, _, 'element'),
			tap(callProperty('sortOn', 'index', Array.NUMERIC), _)
		)([viewport.y, viewport.bottom]);
	}
}



