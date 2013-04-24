package org.tinytlf.parsers
{
	import asx.array.pluck;
	import asx.fn.K;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.aritize;
	import asx.fn.callProperty;
	import asx.fn.apply;
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
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.handlers.printComplete;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.lambdas.updateCache;
	import org.tinytlf.types.CSS;
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
	public function container(element:DOMElement/*<DOMNode>*/,
							  uiFactory:Function,
							  parserFactory:Function):IObservable/*Array<DOMElement, DisplayObject>*/ {
		
		const root:CSS = uiFactory('css')();
		
		const rendered:ISubject = element.rendered;
		const container:DisplayObjectContainer = uiFactory(element.key)(element);
		const region:Region = element.region;
		const viewports:IObservable = region.viewports.takeUntil(element.count());
		const cache:Virtualizer = region.cache;
		
		const subscriptions:CompositeCancelable = new CompositeCancelable();
		const visibleCache:Object = {};
		const elementCache:Object = DOMElement.cache;
		
		const nodeToDOMElement:Function = mapNodesToDOMElements(region, elementCache, root);
		const updateDOMElement:Function = mapDOMElementUpdates(
			visibleCache,
			durationSelector(viewports, cache),
			childSelector(container, uiFactory, parserFactory),
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
			callProperty('concatMany')
		);
		
		const reportUpdate:Function = sequence(
			tap(updateCache, _),
			updateEvent,
			container.dispatchEvent
		);
		
		const expandUpdate:Function = function(...args):IObservable {
			
			// NOTE: I could/should be returning an Observable that dispatches
			// when the UI dispatches the "rendered" event, but my layout
			// algorithms are synchronous and returning a value Observable
			// avoids lag in getting the container on the screen.
			
			container.dispatchEvent(renderEvent());
			
			return Observable.value([element, container]);
		};
		
		const virtualizationObs:IObservable = virtualize(element, distinct, selectVisible, reportUpdate, expandUpdate);
		// If there haven't been any node updates or there aren't any new nodes
		// scrolled into view, 
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
			printError('container', true)
		);
	}
}

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.apply;
import asx.fn.ifElse;
import asx.fn.noop;
import asx.fn.partial;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.geom.Rectangle;

import org.tinytlf.enumerables.cachedDOMElements;
import org.tinytlf.handlers.printError;
import org.tinytlf.lambdas.toInheritanceChain;
import org.tinytlf.types.CSS;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.DOMNode;
import org.tinytlf.types.Region;

import raix.reactive.CompositeCancelable;
import raix.reactive.ICancelable;
import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.Observable;
import raix.reactive.Observer;

import trxcllnt.vr.Virtualizer;

internal function haveNewNodesScrolledIntoView(a:Array, b:Array):Boolean {
	
	// Obvs if either is null, do an update.
	if(!a || !b) return false;
	
	const oldnode:DOMNode = a[0];
	const newnode:DOMNode = b[0];
	
	// If the node children differ, do an update.
	if(oldnode.children.length != newnode.children.length) return false;
	
	const oldport:Rectangle = a[1];
	const newport:Rectangle = b[1];
	const cache:Virtualizer = b[2];
	
	// If the cache is smaller than the viewport, do an update.
	if(cache.size < newport.bottom) return false;
	
	const oldKeys:Array = pluck(cachedDOMElements(oldport, cache), 'key');
	const newKeys:Array = pluck(cachedDOMElements(newport, cache), 'key');
	
	const oldStr:String = '[' + oldKeys.join('], [') + ']';
	const newStr:String = '[' + newKeys.join('], [') + ']';
	
	// If there are different children in view, do an update.
	if(oldStr !== newStr) return false;
	
	// If their styles changed, do an update.
	return oldnode.toString() === newnode.toString();
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

internal function mapNodesToDOMElements(region:Region, elements:Object, css:CSS):Function {
	return function(node:XML):DOMElement {
		
		const key:String = toInheritanceChain(node);
		
		if(elements.hasOwnProperty(key)) return elements[key];
		
		const childRegion:Region = new Region(region.vScroll, region.hScroll);
		childRegion.width = region.width;
		childRegion.height = region.height;
		childRegion.viewport = new Rectangle(0, 0, childRegion.width, childRegion.height);
		
		return elements[key] = new DOMElement(childRegion, key, new DOMNode(node, css));
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
	};
};

internal function nodeIsEmpty(node:DOMNode):Boolean {
	return node.value == '';
};

internal function nodeScrolledOffScreen(viewport:Rectangle, element:DOMElement, cache:Virtualizer):Boolean {
	
	if(cache.getIndex(element) == -1) return false;
	
	const cachedElements:Array = cachedDOMElements(viewport, cache);
	const elementIsVisible:Boolean = Boolean(detect(cachedElements, partial(areEqual, element)));
	
	return elementIsVisible == false;
};

internal function childSelector(container:DisplayObjectContainer,
								uiFactory:Function,
								parserFactory:Function):Function {
	
	return function(child:DOMElement):ICancelable {
		const createChild:Function = parserFactory(child.key);
		const childObservable:IObservable = createChild(child, uiFactory, parserFactory);
		return childObservable.subscribeWith(createChildObserver(container));
	};
	
};

internal function createChildObserver(container:DisplayObjectContainer):IObserver {
	var removeChild:Function = noop;
	
	const complete:Function = function():void {
		removeChild();
	};
	
	const next:Function = apply(function(element:DOMElement, child:DisplayObject):void {
		
		if(child == null) {
			return;
		}
		
		removeChild = ifElse(
			partial(container.contains, child),
			partial(container.removeChild, child),
			noop
		);
		
		const nodeIndex:int = element.index;
		const childIndex:int = Math.max(Math.min(nodeIndex, container.numChildren), 0);
		
		if(container.contains(child) && container.getChildIndex(child) == childIndex) {
			return;
		}
		
		container.addChildAt(child, childIndex);
	});
	
	return Observer.create(next, complete, printError('child rendering', true));
};
