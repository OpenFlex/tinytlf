package org.tinytlf.parsers.block
{
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.setProperty;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.enumerables.visibleValues;
	import org.tinytlf.observables.Values;
	
	import raix.interactive.IEnumerable;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	internal function selectVisibleChildren(parent:Values):Function{
		return function(node:XML, viewport:Rectangle, cache:Virtualizer):IEnumerable {
			
			const elements:XMLList = node.elements();
			
			return visibleValues(elements, viewport.y, viewport.bottom, cache).
				map(sequence(
					setProperty('width', parent.width),
					setProperty('viewport', parent.viewport)
				)).
				takeWhile(partial(roomToRender, parent));
		}
	}
}
import flash.geom.Rectangle;

import org.tinytlf.observables.Values;

import trxcllnt.vr.Virtualizer;

internal function roomToRender(parent:Values, child:Values):Boolean {
	
	const viewport:Rectangle = parent.viewport;
	const cache:Virtualizer = parent.cache;
	
	if(cache.getIndex(child) != -1) {
		// If the element is cached and it intersects with the
		// viewport, render it.
		
		const bounds:Rectangle = new Rectangle(
			viewport.x,
			cache.getStart(child),
			viewport.width,
			cache.getSize(child)
		);
		
		return viewport.intersects(bounds);
	}
	
	// If there's still room in the viewport, render the next element.
	return cache.size <= viewport.bottom + 250; // magic
};

