package org.tinytlf.parsers.block
{
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.setProperty;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.enumerables.visibleValues;
	import org.tinytlf.views.layout.sizeBlockChild;
	import org.tinytlf.observables.Values;
	
	import raix.interactive.IEnumerable;
	
	import trxcllnt.ds.HRTree;

	/**
	 * @author ptaylor
	 */
	internal function selectVisibleChildren(parent:Values):Function {
		return function(node:XML, viewport:Rectangle, cache:HRTree):IEnumerable {
			
			const elements:XMLList = node.elements();
			
			return visibleValues(elements, viewport, cache).
				map(partial(sizeBlockChild, parent)).
				takeWhile(partial(roomToRender, parent));
		}
	}
}
import flash.geom.Rectangle;

import org.tinytlf.observables.Values;

import trxcllnt.ds.HRTree;

internal function roomToRender(parent:Values, child:Values):Boolean {
	
	const viewport:Rectangle = parent.viewport;
	const cache:HRTree = parent.cache;
	const mbr:Rectangle = cache.mbr;
	
	if(cache.hasItem(child) != -1) {
		// If the element is cached and it intersects with the
		// viewport, render it.
		
		const bounds:Rectangle = new Rectangle(child.x, child.y, child.width, child.height);
		
		return viewport.intersects(bounds);
	}
	
	// If there's still room in the viewport, render the next element.
	return mbr.bottom <= viewport.bottom + 250; // magic
};

