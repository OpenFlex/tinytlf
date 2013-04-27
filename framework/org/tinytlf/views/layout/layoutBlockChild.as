package org.tinytlf.views.layout
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.tinytlf.fn.updateCache;
	import org.tinytlf.observables.Values;
	
	import trxcllnt.ds.HRTree;

	/**
	 * @author ptaylor
	 */
	public function layoutBlockChild(parent:Values, prev:Rectangle, child:Values):Rectangle {
		
		const bounds:Rectangle = new Rectangle(parent.x, parent.y, parent.width, parent.height);
		const cache:HRTree = parent.cache;
		
		const display:String = child.display || 'block';
		
		if(display == 'block') {
			child.x = bounds.x;
			child.y = prev.bottom;
		} else if(display == 'inline-block' || display == 'inline') {
			if(prev.left + child.width > bounds.left) {
				child.x = bounds.x;
				child.y = prev.bottom;
			} else {
				child.x = prev.left;
				child.y = prev.y;
			}
		}
		
		const rect:Rectangle = new Rectangle(child.x, child.y, child.width, child.height);
		
		cache.update(rect, child);
		
		return rect;
	}
}