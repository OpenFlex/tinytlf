package org.tinytlf.observers
{
	import asx.fn.apply;
	
	import org.tinytlf.fn.updateCache;
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObserver;
	import raix.reactive.Observer;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function updateCacheObserver(cache:Virtualizer, field:String):IObserver {
		return Observer.create(apply(function(element:Values, value:*):void {
			updateCache(cache, element, value[field]);
		}));
	}
}