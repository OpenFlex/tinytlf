package org.tinytlf.actors
{
	import asx.fn.ifElse;
	import asx.fn.partial;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.DOMElement;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.IEnumerator;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function visibleDOMElements(elementsCache:Object,
									   viewports:IObservable,
									   cache:Virtualizer):Function {
		
		const keySelector:Function = toInheritanceChain;
		const durationSelector:Function = partial(filterNodeLifetime, viewports, cache, {});
		const activeElements:Object = {};
		
		return function(visibleXMLElements:IEnumerable	/*[visible] <XML>*/,
						viewport:Rectangle):IObservable /*[visible] <DOMElement<XML>>*/ {
			
			// Theoretically the cache is being updated async by our subscribers.
			// TODO: Compare based on block progression.
			const processingWithinViewport:Function = function(element:DOMElement):Boolean {
				
				// If there's still room in the viewport, render the next element.
				if(cache.size <= viewport.bottom) return true;
				
				if(cache.getIndex(element) != -1) {
					// If the element is cached and it intersects with the
					// viewport, render it.
					return viewport.intersects(new Rectangle(
						viewport.x,
						cache.getStart(element),
						viewport.width,
						cache.getSize(element)
					));
				}
				
				// TODO: tweak this shit.
				
				// If this element hasn't been rendered or cached yet but is
				// within the acceptable limits of overflow so we can show a lot
				// of scrollbar, render it also.
//				if(cache.size >= viewport.bottom + 13000)
//					return false;
				
//				if(cache.size >= viewport.bottom + 100)
//					return false;
				
				return false;
			};
			
			const elements:IEnumerable /*[visible] <DOMElement>*/ = visibleXMLElements.
				map(function(node:XML):DOMElement {
					const key:String = keySelector(node);
					return elementsCache[key] ||= new DOMElement(key, node);
				}).
				takeWhile(processingWithinViewport);
			
			return Observable.create(function(observer:IObserver):Function {
				const subscriptions:CompositeCancelable = new CompositeCancelable();
				
				const itr:IEnumerator = elements.getEnumerator();
				
				var canceled:Boolean = false;
				
				const iterate:Function = function():void {
					if(canceled) return;
					
					const element:DOMElement = itr.current;
					const key:String = element.key;
					
					subscriptions.add(element.rendered.take(1).subscribe(null, recurse));
					
					if(key in activeElements) {
						Scheduler.immediate.schedule(partial(element.update, element.node), 1)
					} else {
						IObservable(durationSelector(element)).take(1).subscribe(null, function():void {
							element.onCompleted();
							delete activeElements[key];
						});
						
						observer.onNext(activeElements[key] = element);
					}
				};
				
				const recurse:Function = ifElse(
					itr.moveNext,
					iterate,
					observer.onCompleted
				);
				
				recurse();
				
				return function():void {
					canceled = true;
					subscriptions.cancel();
				}
			});
		};
	}
}

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.partial;

import flash.geom.Rectangle;

import org.tinytlf.enumerables.cachedDOMElements;
import org.tinytlf.types.DOMElement;

import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.vr.Virtualizer;

internal function filterNodeLifetime(viewports:IObservable,
									 cache:Virtualizer,
									 keyCache:Object,
									 element:DOMElement):IObservable {
	const key:String = element.key;
	
	return Observable.amb([
		element.filter(nodeIsEmpty),
		viewports.filter(partial(nodeScrolledOffScreen, _, keyCache, element.key, cache))
	]);
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}

internal function nodeScrolledOffScreen(viewport:Rectangle, keyCache:Object, key:String, cache:Virtualizer):Boolean {
	
	const firstSighting:Boolean = (key in keyCache) == false;
	keyCache[key] = true;
	
	if(firstSighting == true) return false;
	
	const cached:Array = cachedDOMElements(viewport, cache);
	const keys:Array = pluck(cached, 'key');
	const keyIsVisible:Boolean = Boolean(detect(keys, partial(areEqual, key)));
	
	return keyIsVisible == false;
}
