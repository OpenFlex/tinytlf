package org.tinytlf.parsers.block
{
	import org.tinytlf.observables.Values;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.MutableCancelable;

	/**
	 * @author ptaylor
	 */
	public function monitorChildLifetime(observerSelector:Function,
										 durationSelector:Function,
										 subscriptions:Object):Function {
		
		return function(child:Values, childObservable:IObservable):IObservable {
			
			const key:String = child.key;
			
			if(subscriptions.hasOwnProperty(key)) return childObservable;
			
			const durationSubscription:MutableCancelable = new MutableCancelable();
			const lifetimeSubscription:MutableCancelable = new MutableCancelable();
			
			const composite:CompositeCancelable = new CompositeCancelable([durationSubscription, lifetimeSubscription]);
			
			subscriptions[key] = composite;
			
			const close:Function = function():void {
				composite.cancel();
				delete subscriptions[key];
			};
			
			const durationObservable:IObservable = IObservable(durationSelector(child)).take(1);
			
			lifetimeSubscription.cancelable = childObservable.
				takeUntil(durationObservable).
				peek(null, close).
				subscribeWith(observerSelector(child));
			
			return childObservable;
		};
	}
}