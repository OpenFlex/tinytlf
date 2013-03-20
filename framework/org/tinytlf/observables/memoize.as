package org.tinytlf.observables
{
	import flash.utils.Dictionary;
	
	import asx.fn.I;
	import asx.fn.K;
	import asx.fn.areEqual;
	import asx.fn.aritize;
	import asx.fn.guard;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.setProperty;
	import asx.object.isAn;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function memoize(source:IObservable, keySelector:Function, cache:Dictionary = null):IObservable {
		
		cache ||= defaultCache;
		
		const key:* = keySelector();
		const cached:IObservable = cache[key];
		
		const store:Function = function(observableFactory:Function, value:*):IObservable {
			return cache[key] = observableFactory(value);
		};
		
		const storeNext:Function = partial(store, Observable.value);
		const storeError:Function = partial(store, Observable.error);
		
		const sourceWithPeek:IObservable = source.peek(storeNext, noop, storeError);
		
		const errorHandled:IObservable = Observable.value(cached).peek(storeNext);
		const peekWithErrorHandled:IObservable = sourceWithPeek.catchError(errorHandled);
		
		const defaultAction:IObservable = cached ? peekWithErrorHandled : sourceWithPeek;
		
		return Observable.lookup(keySelector, cache).first().
			mapMany(ifElse(
				partial(isAn, Error),
				K(defaultAction),
				Observable.value
			));
	}
}
import flash.utils.Dictionary;

internal const defaultCache:Dictionary = new Dictionary(false);
