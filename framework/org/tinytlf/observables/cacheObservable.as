package org.tinytlf.observables
{
	import org.tinytlf.handlers.printComplete;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.handlers.printFinally;
	import org.tinytlf.handlers.printNext;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;

	/**
	 * This should be Observable.lookup.
	 * 
	 * @author ptaylor
	 */
	public function cacheObservable(observableCache:Object,
									observableFactory:Function,
									element:Values):IObservable {
		
		return Observable.createWithCancelable(function(observer:IObserver):ICancelable {
			
			const key:String = element.key;
			const obs:IObservable = observableCache.hasOwnProperty(key) ?
				observableCache[key] :
				observableFactory(element);
			
			return IObservable(observableCache[key] = obs).
//				peek(printNext(key), printComplete(key), printError(key, true)).
//				finallyAction(printFinally(key)).
				subscribeWith(observer);
		});
	}
}