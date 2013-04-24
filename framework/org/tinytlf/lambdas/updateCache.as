package org.tinytlf.lambdas
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	import org.tinytlf.types.DOMElement;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function updateCache(viewport:Rectangle,
								cache:Virtualizer,
								element:DOMElement,
								display:DisplayObject):void {
		
		const size:Number = Math.max(display.height, 1);
		const childIndex:int = element.index;
		const index:int = cache.getIndex(element);
		
		if(index == -1) {
			cache.add(element, size);
		} else if(index != childIndex) {
			if(childIndex == -1) {
				cache.setSizeAt(index, size);
			} else {
				cache.removeAt(index);
				cache.addAt(element, childIndex, size);
			}
		} else {
			cache.setSizeAt(index, size);
		}
	}
}