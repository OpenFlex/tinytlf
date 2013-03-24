package org.tinytlf.actors2
{
	import flash.display.DisplayObjectContainer;
	
	import asx.fn.I;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.number.eq;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.handlers.printAndCancel;
	import org.tinytlf.handlers.printComplete;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.lambdas.getElementsLength;
	import org.tinytlf.lambdas.toStyleable;
	import org.tinytlf.lambdas.updateCacheAfterRender;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Rendered;
	
	import raix.interactive.IEnumerable;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	import raix.reactive.subjects.IConnectableObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function renderDOMContainer(parent:Region,
									   updates:DOMElement/*<XML>*/,
									   uiFactory:Function/*<String>:<Function<Region>:<DisplayObjectContainer>>*/,
									   childFactory:Function,
									   styles:IObservable/*<CSS>*/):IObservable/*<Rendered>*/ {
		
		const region:Region = new Region(parent.vScroll, parent.hScroll);
		
		region.width = parent.width;
		region.height = parent.height;
		
		const cache:RTree = region.cache;
		const key:String = updates.key;
		const viewports:IObservable = region.viewports;
		
		const ui:DisplayObjectContainer = uiFactory(key)(region);
		
		const updatesWithoutChildren:IObservable /*<XML>*/ = updates.filter(sequence(
			getElementsLength,
			partial(eq, 0)
		));
		
		const visibleXMLWindows:IObservable /*<XML>*/ = updates.combineLatest(viewports, args).
			// Only accept updates when the latest XML node has element children
			filter(distribute(sequence(I, not(sequence(
				getElementsLength,
				partial(eq, 0)
			))))).
			// Map all children to a list of visible children, starting with
			// previously cached children
			map(distribute(partial(visibleXMLElements, _, _, cache))).
			takeUntil(updates.count());
		
		const groupDOMElementLifetimes:Function = visibleDOMElements(DOMElement.cache, viewports, cache);
		const domElementWindows:IObservable = visibleXMLWindows.
			map(function(window:IEnumerable):Array {
				return [window, region.viewport];
			}).
			map(sequence(
				distribute(groupDOMElementLifetimes),
				// publish the inner sequence
				callProperty('publish'),
				callProperty('refCount')
			)).
			publish().
			refCount();
		
		const renderedDOMElementWindows:IObservable = domElementWindows.
			map(function(window:IObservable):IObservable {
				return window.map(function(element:DOMElement):IObservable /*<Rendered>*/ {
					return childFactory(element.key)(region, element, uiFactory, childFactory, styles);
				});
			});
		
		const childObserver:IObserver = createChildrenObserver(ui);
		const childUpdates:IObservable = renderedDOMElementWindows.
			switchMany(callProperty('peekWith', childObserver));
		
		const elementsHaveRendered:IObservable = domElementWindows.switchMany(callProperty('count'));
		
		const regionStyleables:IObservable = updates.combineLatest(styles, toStyleable);
		const readyToRender:IObservable = updatesWithoutChildren.merge(elementsHaveRendered);
		
		const subscriptions:CompositeCancelable = new CompositeCancelable([
			
			// Apply styles to the region
			regionStyleables.subscribe(region.mergeWith),
			
			// Bind the children lifetimes to the UI container's display list
			childUpdates.subscribe(noop, cancelChildSubscriptions, printError('child updates')),
			
			// If the new node doesn't have any children, dispatch a render
			// event immediately.
			// 
			// When all the render Observables in a given window have completed
			// dispatch a "render" event on the UI.
			readyToRender.subscribe(sequence(renderEvent, ui.dispatchEvent)),
		]);
		
		updates.subscribe(
			noop,
			printAndCancel(subscriptions, printComplete, 'render_container'),
			printAndCancel(subscriptions, printError, 'render_container')
		);
		
//		subscriptions.add(domElementWindows.connect());
		
		// Listen for the "rendered" event from the UI. Pass the Rendered
		// instance to the rendered Subject's onNext()
		return renderedEventsToValues(updates, ui).
			delay(10).
			// When the 'rendered' Subject emits a value, create a new Envelope
			// for the UI container and insert/update the RTree's cache
			peek(updateCacheAfterRender(parent.cache)).
			// Notify the current rendered subject of completion.
			peek(function(rendered:Rendered):void {
				updates.rendered.onNext(rendered);
				updates.rendered.onCompleted();
			}).
			takeUntil(updates.count());
	}
}
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.utils.Dictionary;

import asx.fn.K;
import asx.fn._;
import asx.fn.aritize;
import asx.fn.ifElse;
import asx.fn.noop;
import asx.fn.partial;
import asx.fn.sequence;
import asx.object.newInstance_;

import org.tinytlf.events.renderedEvent;
import org.tinytlf.handlers.printError;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.Rendered;

import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.Observable;
import raix.reactive.Observer;

internal function renderedEventsToValues(updates:DOMElement, ui:DisplayObjectContainer):IObservable {
	
	// Listen for the "rendered" event from the UI
	const uiRendered:IObservable = Observable.fromEvent(ui, renderedEvent().type);
	
	// Build a function that accepts an XML node and instantiates a new 'Rendered' instance.
	const mapRendered:Function = partial(aritize(newInstance_, 3), Rendered, _, ui);
	
	// Subscribe to the result of uiRendered.map(node), but only while the node
	// is the latest value. When the UI dispatches the 'rendered' Event, the
	// latest node is returned and passed to mapRendered, creating the most
	// recent Rendered instance.
	
	return updates.switchMany(sequence(K(updates), K, uiRendered.map)).map(mapRendered);
}

internal const childSubscriptions:Dictionary = new Dictionary(false);

internal function cancelChildSubscriptions():void {
	for(var child:* in childSubscriptions) {
		childSubscriptions[child].cancel();
		delete childSubscriptions[child];
	}
}

internal function createChildrenObserver(ui:DisplayObjectContainer):IObserver {
	
	var ordering:int = -1;
	var activeChildSubscriptions:Dictionary = new Dictionary(false);
	
	const indexCache:Dictionary = new Dictionary(false);
	
	const next:Function = function(child:IObservable):void {
		
		activeChildSubscriptions[child] = ++ordering;
		
		if(child in indexCache) {
			if(indexCache[child] == ordering) return;
			childSubscriptions[child].cancel();
		}
		
		indexCache[child] = ordering;
		childSubscriptions[child] = child.finallyAction(function():void {
			delete activeChildSubscriptions[child];
		}).
		subscribeWith(createChildObserver(ui, ordering));
	};
	
	const complete:Function = function():void {
		ordering = -1;
		
		for(var child:* in childSubscriptions) {
			if(child in activeChildSubscriptions)
				continue;
			
			childSubscriptions[child].cancel();
			delete childSubscriptions[child];
		}
	};
	
	return Observer.create(next, complete, printError('children list'));
}

internal function createChildObserver(container:DisplayObjectContainer, index:int):IObserver {
	var removeChild:Function = noop;
	
	const complete:Function = function():void {
		removeChild();
	};
	
	const next:Function = function(rendered:Rendered):void {
		removeChild = ifElse(
			partial(container.contains, rendered.display),
			partial(container.removeChild, rendered.display),
			noop
		);
		
		const child:DisplayObject = rendered.display;
		const childIndex:int = Math.min(index, container.numChildren);
		
		if(container.contains(child)) {
			return;
		}
		
		container.addChildAt(child, childIndex);
	};
	
	return Observer.create(next, complete, printError('child rendering'));
}
