package org.tinytlf.lambdas
{
	import raix.reactive.Cancelable;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;

	/**
	 * @author ptaylor
	 */
	public function sideEffect(selector:Function, subscriptions:CompositeCancelable = null):Function {
		var cancelable:ICancelable = Cancelable.empty;
		if(subscriptions) subscriptions.add(cancelable);
		
		return function(...args):void {
			cancelable.cancel();
			if(subscriptions) subscriptions.remove(cancelable);
			
			cancelable = selector.apply(null, args);
			if(subscriptions && cancelable) subscriptions.add(cancelable);
		}
	}
}