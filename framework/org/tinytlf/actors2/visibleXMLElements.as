package org.tinytlf.actors2
{
	import flash.geom.Rectangle;
	
	import asx.fn._;
	import asx.fn.callXMLProperty;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.number.gt;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.toEnumerable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function visibleXMLElements(node:XML,
									   viewport:Rectangle,
									   cache:RTree):IEnumerable/*[visible] <XML>*/ {
		
		const cached:IEnumerable = toEnumerable(cachedXMLElements(viewport, cache));
		
		// TODO: What if an element was inserted between two cached elements?
		
		const last:XML = cached.lastOrDefault() as XML;
		const rest:IEnumerable = last == null ?
			elementsOfXML(node, 0) :
			elementsOfXML(node, last.childIndex());
		
		return cached.concat(rest);
	}
}