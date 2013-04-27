package org.tinytlf.parsers.block
{
	import asx.array.last;
	import asx.array.tail;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.pull;
	import asx.fn.sequence;
	
	import flash.display.DisplayObjectContainer;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.ds.HRTree;

	/**
	 * @author ptaylor
	 */
	public function container(create:Function,
							  render:Function,
							  values:Values):IObservable {
		
		const view:DisplayObjectContainer = create(values);
		const cache:HRTree = values.cache;
		
		const updates:IObservable = values.
			combine('html', 'viewport').
			map(distribute(
				pull(values, 'toString'),
				pull(values, 'html'),
				pull(values, 'viewport'),
				pull(values, 'cache')
			)).
			distinctUntilChanged(not(allowContainerUpdate)).
			map(tail);
		
		const subscriptions:Object = {};
		const observerSelector:Function = partial(childObserverSelector, view, cache, values);
		const durationSelector:Function = partial(childDurationSelector, values);
		const monitor:Function = monitorChildLifetime(observerSelector, durationSelector, subscriptions);
		const visibleSelector:Function = selectVisibleChildren(values);
		
		const virt:Function = virtualizeChildren(visibleSelector, render, monitor);
		
		const peekUpdate:Function = sequence(
			args, last, ifElse(view.contains, noop, view.addChild),
			updateEvent, view.dispatchEvent
		);
		const expandUpdate:Function = function(...args):IObservable {
			// NOTE: I could/should be returning an Observable that dispatches
			// when the UI dispatches the "rendered" event, but my layout
			// algorithms are synchronous, and returning a value Observable
			// avoids a lag in getting the container on the screen.
			view.dispatchEvent(renderEvent());
			return Observable.value([values, view]);
		};
		
		const rendered:ISubject = new BehaviorSubject();
		
		const children:IObservable = virt(values, updates, peekUpdate, expandUpdate);
		
		children.subscribeWith(rendered);
		
		return rendered;
	}
}
import asx.array.detect;
import asx.array.last;
import asx.array.map;
import asx.fn._;
import asx.fn.apply;
import asx.fn.areEqual;
import asx.fn.not;
import asx.fn.partial;
import asx.fn.sequence;

import flash.display.DisplayObjectContainer;
import flash.geom.Rectangle;

import org.tinytlf.enumerables.cachedValues;
import org.tinytlf.observables.Values;
import org.tinytlf.observers.displayListObserver;
import org.tinytlf.observers.updateCacheObserver;
import org.tinytlf.observers.updateViewportObserver;

import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.ISubject;
import raix.reactive.Subject;

import trxcllnt.ds.HRTree;

internal function childObserverSelector(ui:DisplayObjectContainer, cache:HRTree, parent:Values, child:Values):IObserver {
	
	const displayObserver:IObserver = displayListObserver(ui);
//	const cacheObserver:IObserver = updateCacheObserver(cache, 'height');
	
	const update:ISubject = new Subject();
	const notNull:IObservable = update.filter(sequence(last, not(partial(areEqual, null))));
	
	notNull.subscribeWith(displayObserver);
//	notNull.subscribeWith(cacheObserver);
	
	parent.combine('viewport').
		map(last).
		takeUntil(update.count()).
		subscribeWith(updateViewportObserver(child));
	
	return update;
}

internal function childDurationSelector(parent:Values, child:Values):IObservable {
	return parent.combine('viewport', 'cache').
		map(partial(map, _, last)).
		filter(apply(partial(childScrolledOffScreen, child)));
};

internal function childScrolledOffScreen(child:Values, viewport:Rectangle, cache:HRTree):Boolean {
	if(cache.hasItem(child) == false) return false;
	
	const cached:Array = cachedValues(cache, viewport);
	const elementIsVisible:Boolean = Boolean(detect(cached, partial(areEqual, child)));
	
	return elementIsVisible == false;
};

