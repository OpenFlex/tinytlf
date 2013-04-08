package org.tinytlf.actors2
{
	import flash.geom.Rectangle;
	
	import asx.fn.ifElse;
	import asx.fn.partial;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.DOMElement;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.IEnumerator;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.Node;
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function visibleDOMElements(elementsCache:Object,
									   viewports:IObservable,
									   cache:RTree):Function {
		
		const keySelector:Function = toInheritanceChain;
		const durationSelector:Function = partial(filterNodeLifetime, viewports, cache);
		const activeElements:Object = {};
		
		return function(visibleXMLElements:IEnumerable	/*[visible] <XML>*/,
						viewport:Rectangle):IObservable /*[visible] <DOMElement<XML>>*/ {
			
			// Theoretically the cache is being updated async by our subscribers.
			// TODO: Compare based on block progression.
			const processingWithinViewport:Function = function(element:DOMElement):Boolean {
				
				const eCache:Envelope = cache.envelope; // re-query for the Envelope value
				
				// If there's still room in the viewport, render the next element.
				if(eCache.bottom <= viewport.bottom) return true;
				
				const n0:Node = cache.find(element);
				
				if(n0) {
					const e0:Envelope = n0.envelope;
					
					// If this element is in the viewport, render it.
					return viewport.intersects(e0);
				}
				
				// If this element hasn't been rendered/cached yet but is within
				// the acceptable limits of overflow so we can show a lot of
				// scrollbar, render it also.
				if(eCache.height >= viewport.bottom + 13000)
					return false;
				
				if(eCache.width >= viewport.right + 13000)
					return false;
				
				return true;
			};
			
			const elements:IEnumerable /*[visible] <DOMElement>*/ = visibleXMLElements.
				map(function(node:XML):DOMElement {
					const key:String = keySelector(node);
					const element:DOMElement = elementsCache[key] || new DOMElement(key, node);
					return (elementsCache[key] = element.update(node));
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
					
					if(!(key in activeElements)) {
						
						IObservable(durationSelector(element)).take(1).subscribe(null, function():void {
							element.onCompleted();
							delete activeElements[key];
						});
						
						activeElements[key] = element;
						
						observer.onNext(element);
					}
					
					subscriptions.add(element.rendered.take(1).subscribe(null, recurse));
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

import flash.geom.Rectangle;

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.getProperty;
import asx.fn.partial;
import asx.fn.sequence;

import org.tinytlf.actors2.cachedDOMElements;
import org.tinytlf.types.DOMElement;

import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.ds.RTree;

internal function filterNodeLifetime(viewports:IObservable,
									 cache:RTree,
									 element:DOMElement):IObservable {
	return Observable.amb([
		element.filter(nodeIsEmpty),
		viewports.filter(partial(nodeScrolledOffScreen, _, element.key, cache))
	]);
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}

internal function nodeScrolledOffScreen(viewport:Rectangle, key:String, cache:RTree):Boolean {
	
	const keyIsCached:Boolean = detect(cache.values(), sequence(
		getProperty('element'),
		getProperty('key'),
		partial(areEqual, key)
	));
	
	if(keyIsCached == false) return false;
	
	const cached:Array = cachedDOMElements(viewport, cache);
	const keys:Array = pluck(cached, 'key');
	const keyInKeys:Boolean = detect(keys, partial(areEqual, key));
	
	return keyInKeys == false;
}
