package org.tinytlf.enumerables
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.types.DOMNode;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.toEnumerable;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function visibleXMLElements(node:DOMNode,
									   viewport:Rectangle,
									   cache:Virtualizer):IEnumerable/*[visible] <XML>*/ {
		
		const cached:IEnumerable = toEnumerable(cachedXMLElements(viewport, cache));
		
		// TODO: What if an element was inserted between two cached elements?
		
		const last:XML = cached.lastOrDefault() as XML;
		const rest:IEnumerable =  generateFrom(node.elements, last == null ? 0 : last.childIndex());
		
		return cached.skipLast(1).concat(rest);
	}
}