package org.tinytlf.fn
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.observables.Values;
	
	import trxcllnt.ds.HRTree;

	/**
	 * @author ptaylor
	 */
	public function updateCache(cache:HRTree,
								element:Values,
								size:Rectangle):void {
		cache.update(size, element);
	}
}