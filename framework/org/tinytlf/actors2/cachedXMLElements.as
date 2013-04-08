package org.tinytlf.actors2
{
	import asx.array.pluck;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.types.Virtualizer;
	
	/**
	 * Mutates a (Rectangle, RTree) into an Array<XML> where each element in
	 * Array<XML> intersects with the viewport Rectangle.
	 * 
	 * @author ptaylor
	 */
	public function cachedXMLElements(viewport:Rectangle, cache:Virtualizer):Array/*<XML>*/ {
		return pluck(cachedDOMElements(viewport, cache), 'node');
	}
}


