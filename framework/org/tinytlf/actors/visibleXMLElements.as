package org.tinytlf.actors
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.types.Virtualizer;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.toEnumerable;

	/**
	 * @author ptaylor
	 */
	public function visibleXMLElements(node:XML,
									   viewport:Rectangle,
									   cache:Virtualizer):IEnumerable/*[visible] <XML>*/ {
		
		const cached:IEnumerable = toEnumerable(cachedXMLElements(viewport, cache));
		
		// TODO: What if an element was inserted between two cached elements?
		
		const last:XML = cached.lastOrDefault() as XML;
		const rest:IEnumerable = last == null ?
			elementsOfXML(node, 0) :
			elementsOfXML(node, last.childIndex());
		
		return cached.concat(rest);
	}
}