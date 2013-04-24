package org.tinytlf.observables
{
	import asx.array.forEach;
	import asx.array.invoke;
	import asx.fn.I;
	import asx.fn.apply;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	public function expandVirtualized(visibleSelector:Function/*(...args):IEnumerable*/,
									  peek:Function/*(...args):void*/,
									  expandUnique:Function/*(...args):IObservable*/,
									  expandSimilar:Function/*(...args):IObservable*/,
									  
									  enter:Function/*:IObservable*/,
									  exit:Function/*:IObservable*/,
									  update:Function/*(child:Values):IObserver*/,
									  
									  similar:IObservable,
									  unique:IObservable,
									  element:Values):IObservable {
		
		const rendered:ISubject = new BehaviorSubject();
		const visibleSubscriptions:Object = {};
		
		const observeChild:Function = partial(
			subscribeToChildLifetime,
			update, exit, visibleSubscriptions
		);
		
		const selectVisible:Function = sequence(
			visibleSelector,
			callProperty('map', distribute(I, enter)),
			callProperty('map', apply(observeChild)),
			callProperty('map', callProperty('take', 1)),
			callProperty('concatMany')
		);
		
		const vObs:IObservable = virtualize(element, unique, selectVisible, peek, expandUnique);
//		const sObs:IObservable = similar.switchMany(expandSimilar);
//		const aObs:IObservable = vObs.//merge(sObs).
		vObs.peek(null, function():void{
			for(var key:String in visibleSubscriptions) {
				const subscriptions:Array = visibleSubscriptions[key];
				invoke(subscriptions, 'cancel');
				delete visibleSubscriptions[key];
			}
		}).
		subscribeWith(rendered);
		
		return rendered;
//		return updateOnSubscribe(aObs, function():void {
//			element.html = element.html;
//		});
	}
}
import asx.array.forEach;
import asx.fn.callProperty;

import org.tinytlf.observables.Values;

import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.MutableCancelable;

internal function subscribeToChildLifetime(observerSelector:Function,
										   durationSelector:Function,
										   subscriptions:Object,
										   child:Values,
										   childRenderObs:IObservable):IObservable {
	
	const key:String = child.key;
	
	// If we're not subscribed, subscribe to the child's entire lifetime,
	// updating the parent's cache, synchronizing the child in the parent's
	// display list, then notifying the parent of child updates.
	if(subscriptions.hasOwnProperty(key) == false) {
		
		const durationSubscription:MutableCancelable = new MutableCancelable();
		const lifetimeSubscription:MutableCancelable = new MutableCancelable();
		
		subscriptions[key] = [lifetimeSubscription, durationSubscription];
		
		const close:Function = function():void {
			if(subscriptions.hasOwnProperty(key) == false) return;
			
			forEach(subscriptions[key], callProperty('cancel'));
			
			delete subscriptions[key];
		};
		
		const durationObservable:IObservable = IObservable(durationSelector(child)).take(1);
		lifetimeSubscription.cancelable = childRenderObs.
			takeUntil(durationObservable).
			peek(null, close).
			subscribeWith(observerSelector(child));
	}
	
	// Return the cached Observable so the virtualization algorithm can
	// subscribe for a single update.
	return childRenderObs;
};

