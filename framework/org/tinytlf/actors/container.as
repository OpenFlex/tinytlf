package org.tinytlf.actors
{
	import asx.array.last;
	import asx.array.pluck;
	import asx.fn.K;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.aritize;
	import asx.fn.callProperty;
	import asx.fn.defer;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.tap;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import org.tinytlf.enumerables.cachedDOMElements;
	import org.tinytlf.enumerables.visibleXMLElements;
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.renderedEventType;
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.handlers.printComplete;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.lambdas.updateCache;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.vr.Virtualizer;
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	public function container(element:DOMElement/*<XML>*/,
							  containerFactory:Function,
							  childFactory:Function):IObservable/*Array<DOMElement, DisplayObject>*/ {
		
		const rendered:ISubject = element.rendered;
		const container:DisplayObjectContainer = containerFactory(element.key)(element);
		const region:Region = element.region;
		const viewports:IObservable = region.viewports.takeUntil(element.count());
		const cache:Virtualizer = region.cache;
		
		const subscriptions:CompositeCancelable = new CompositeCancelable();
		const visibleCache:Object = {};
		const elementCache:Object = DOMElement.cache;
		
		const nodeToDOMElement:Function = mapNodesToDOMElements(region, elementCache);
		const updateDOMElement:Function = mapDOMElementUpdates(
			visibleCache,
			durationSelector(viewports, cache),
			childSelector(container, containerFactory, childFactory),
			subscriptions
		);
		
		const updates:IObservable = element.combineLatest(viewports, args).
			mappend(K(cache)).
			finallyAction(sequence(
				subscriptions.cancel,
				aritize(printComplete('container updates'), 0)
			));
		
		const distinct:IObservable = updates.distinctUntilChanged(haveNewNodesScrolledIntoView);
		
		const selectVisible:Function = sequence(
			visibleXMLElements,
			callProperty('map', nodeToDOMElement),
			callProperty('takeWhile', setupHaltIteration(element)),
			callProperty('map', updateDOMElement),
			callProperty('map', getProperty('rendered')),
			callProperty('concatObservables')
		);
		
		const reportUpdate:Function = sequence(
			tap(updateCache, _),
			sequence(args, last, ifElse(
					not(container.contains),
					container.addChild,
					noop
			)),
			updateEvent,
			container.dispatchEvent
		);
		
		const expandUpdate:Function = function(...args):IObservable {
			
			container.dispatchEvent(renderEvent());
			
			return Observable.value([element, container]);
		};
		
		const virtualizationObs:IObservable = virtualize(element, distinct, selectVisible, reportUpdate, expandUpdate);
		const similar:IObservable = updates.distinctUntilChanged(not(haveNewNodesScrolledIntoView)).
			skip(1).
			switchMany(expandUpdate);
		
		const lifetimeObs:IObservable = virtualizationObs.merge(similar).takeUntil(element.count());
		
		return lifetimeObs.peek(
			function(values:Array):void {
				Scheduler.defaultScheduler.schedule(partial(rendered.onNext, values));
				Scheduler.defaultScheduler.schedule(rendered.onCompleted);
			},
			noop,
			printError('contain2')
		);
	}
}
import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.distribute;
import asx.fn.ifElse;
import asx.fn.noop;
import asx.fn.partial;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.geom.Rectangle;

import org.tinytlf.enumerables.cachedDOMElements;
import org.tinytlf.handlers.printError;
import org.tinytlf.lambdas.toInheritanceChain;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.Region;

import raix.reactive.CompositeCancelable;
import raix.reactive.ICancelable;
import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.Observable;
import raix.reactive.Observer;

import trxcllnt.vr.Virtualizer;

internal function haveNewNodesScrolledIntoView(a:Array, b:Array):Boolean {
	if(!a || !b) return false;
	
	const oldport:Rectangle = a[1];
	const newport:Rectangle = b[1];
	const cache:Virtualizer = b[2];
	
	if(cache.size < newport.bottom) return false;
	
	const oldKeys:Array = pluck(cachedDOMElements(oldport, cache), 'key');
	const newKeys:Array = pluck(cachedDOMElements(newport, cache), 'key');
	
	const oldStr:String = '[' + oldKeys.join('], [') + ']';
	const newStr:String = '[' + newKeys.join('], [') + ']';
	
	return oldStr === newStr;
};

internal function setupHaltIteration(element:DOMElement):Function {
	return function(child:DOMElement):Boolean {
		
		const viewport:Rectangle = element.region.viewport;
		const cache:Virtualizer = element.region.cache;
		
		// If there's still room in the viewport, render the next element.
		if(cache.size <= viewport.bottom) return true;
		
		if(cache.getIndex(child) != -1) {
			// If the element is cached and it intersects with the
			// viewport, render it.
			
			const bounds:Rectangle = new Rectangle(
				viewport.x,
				cache.getStart(child),
				viewport.width,
				cache.getSize(child)
			);
			
			return viewport.intersects(bounds);
		}
		
		return false;
	};
};

internal function mapNodesToDOMElements(region:Region, elements:Object):Function {
	return function(node:XML):DOMElement {
		
		const key:String = toInheritanceChain(node);
		
		if(elements.hasOwnProperty(key)) return elements[key];
		
		const childRegion:Region = new Region(region.vScroll, region.hScroll);
		childRegion.width = region.width;
		childRegion.height = region.height;
		childRegion.viewport = new Rectangle(0, 0, childRegion.width, childRegion.height);
		
		return elements[key] = new DOMElement(childRegion, key, node);
	};
};

internal function mapDOMElementUpdates(visible:Object,
									   durationSelector:Function,
									   childSelector:Function,
									   subscriptions:CompositeCancelable):Function {
	
	return function(element:DOMElement):DOMElement {
		
		const key:String = element.key;
		
		if(visible.hasOwnProperty(key)) {
			return element.update(element.node);
		}
		
		const completed:Function = function():void {
			delete visible[key];
			
			element.onCompleted();
			
			if(durationSubscription) {
				durationSubscription.cancel();
				subscriptions.remove(durationSubscription);
			}
			
			if(lifetimeSubscription) {
				lifetimeSubscription.cancel();
				subscriptions.remove(lifetimeSubscription);
			}
		};
		
		const durationSubscription:ICancelable = durationSelector(element).take(1).subscribe(null, completed);
		const lifetimeSubscription:ICancelable = childSelector(element);
		
		subscriptions.add(durationSubscription);
		subscriptions.add(lifetimeSubscription);
		
		return visible[key] = element;
	}
};

internal function durationSelector(viewports:IObservable,
								   cache:Virtualizer):Function {
	return function(element:DOMElement):IObservable {
		return Observable.amb([
			element.filter(nodeIsEmpty),
			viewports.filter(partial(nodeScrolledOffScreen, _, element, cache))
		]);
	}
};

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
};

internal function nodeScrolledOffScreen(viewport:Rectangle, element:DOMElement, cache:Virtualizer):Boolean {
	
	if(cache.getIndex(element) == -1) return false;
	
	const cachedElements:Array = cachedDOMElements(viewport, cache);
	const elementIsVisible:Boolean = Boolean(detect(cachedElements, partial(areEqual, element)));
	
	return elementIsVisible == false;
};

internal function childSelector(container:DisplayObjectContainer,
								containerFactory:Function,
								childFactory:Function):Function {
	
	return function(child:DOMElement):ICancelable {
		const createChild:Function = childFactory(child.key);
		const childObservable:IObservable = createChild(child, containerFactory, childFactory);
		return childObservable.subscribeWith(createChildObserver(container));
	};
	
};

internal function createChildObserver(container:DisplayObjectContainer):IObserver {
	var removeChild:Function = noop;
	
	const complete:Function = function():void {
		removeChild();
	};
	
	const next:Function = distribute(function(element:DOMElement, child:DisplayObject):void {
		
		removeChild = ifElse(
			partial(container.contains, child),
			partial(container.removeChild, child),
			noop
		);
		
//		const nodeIndex:int = element.node.childIndex();
//		const childIndex:int = Math.max(Math.min(nodeIndex, container.numChildren), 0);
//		
//		if(container.contains(child) && container.getChildIndex(child) == childIndex) {
//			return;
//		}
//		
//		container.addChildAt(child, childIndex);
	});
	
	return Observer.create(next, complete, printError('child rendering', true));
};
