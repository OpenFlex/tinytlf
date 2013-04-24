package org.tinytlf.fn
{
	import org.tinytlf.observables.Values;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function updateCache(cache:Virtualizer,
								element:Values,
								size:Number):void {
		
		size = Math.max(size, 1);
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