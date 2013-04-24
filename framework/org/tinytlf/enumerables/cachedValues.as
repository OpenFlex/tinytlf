package org.tinytlf.enumerables
{
	import asx.fn._;
	import asx.fn.apply;
	import asx.fn.callProperty;
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
	public function cachedValues(start:int, end:int, cache:Virtualizer):Array/*<Values>*/ {
		const cached:Array = cache.slice(start, end);
		cached.sortOn('index', Array.NUMERIC);
		return cached;
	}
}



