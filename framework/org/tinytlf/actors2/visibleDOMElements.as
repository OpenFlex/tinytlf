package org.tinytlf.actors2
{
	import asx.fn.ifElse;
	import asx.fn.partial;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Virtualizer;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.IEnumerator;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;

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
				if(cache.size >= viewport.bottom + 13000)
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

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.not;
import asx.fn.partial;

import flash.geom.Rectangle;

import org.tinytlf.actors2.cachedDOMElements;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.Virtualizer;

import raix.reactive.IObservable;
import raix.reactive.Observable;

internal function filterNodeLifetime(viewports:IObservable,
									 cache:Virtualizer,
									 keyCache:Object,
									 element:DOMElement):IObservable {
	
	const key:String = element.key;
	const firstSighting:Boolean = (key in keyCache) == false;
	
	return Observable.amb([
		element.filter(nodeIsEmpty),
		viewports.filter(partial(nodeScrolledOffScreen, _, element.key, cache))
	]);
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}

internal function nodeScrolledOffScreen(viewport:Rectangle, firstSighting:Boolean, key:String, cache:Virtualizer):Boolean {
	
	if(firstSighting == true) return false;
	
	const cached:Array = cachedDOMElements(viewport, cache);
	const keys:Array = pluck(cached, 'key');
	
	return detect(keys, partial(areEqual, key)) == false;
}
