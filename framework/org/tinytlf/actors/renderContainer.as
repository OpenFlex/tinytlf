package org.tinytlf.actors
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
	import asx.object.isA;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.handlers.printAndCancel;
	import org.tinytlf.handlers.printComplete;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.lambdas.toStyleable;
	import org.tinytlf.lambdas.updateCacheAfterRender;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Rendered;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.subjects.IConnectableObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function renderContainer(parent:Region,
									updates:DOMElement/*<XML>*/,
									uiFactory:Function/*<String>:<Function<Region>:<DisplayObjectContainer>>*/,
									childFactory:Function,
									styles:IObservable/*<CSS>*/):IObservable/*<Rendered>*/ {
		
		styles = styles.filter(isA(CSS));
		
		const region:Region = new Region(parent.vScroll, parent.hScroll);
		
		region.width = parent.width;
		region.height = parent.height;
		
		const cache:RTree = region.cache;
		const key:String = updates.key;
		const viewports:IObservable = region.viewport;
		
		/**
		 * 0. Create the UI container
		 * 1. Track subscriptions
		 * 2. Listen for DOMElement updates and...
		 * 	-	apply the node and CSS styles to the region
		 * 
		 * 	-	TODO:
		 * 		apply the node and CSS styles to the UI container
		 * 
		 * 	-	update/insert the UI container into the RTree when the rendered
		 * 		subject emits a value.
		 * 
		 * 	-	Add a listener for the 'rendered' event from the UI container so
		 * 		we can dispatch a Rendered value on the DOMElement.rendered
		 * 		Subject. Listen first because rendering might be synchronous.
		 * 
		 * 	-	get a list of cached and new visible children
		 * 	-	map the children list into a list of child lifetimes
		 * 	-	map the child lifetimes into a list of DOMElements
		 * 	-	map the list of DOMElements into a list of IObservable<Rendered>s
		 * 	-	wait for all the child IObservable<Rendered>s have completed
		 * 	-	dispatch the 'render' event on the UI container
		 * 		
		 * 	-	wait for the UI container's IObservable<Rendered> to complete
		 * 		
		 * 	-	map the completed IObservable<IObservable<Rendered>> to the last Rendered value
		 */
		
		const ui:DisplayObjectContainer = uiFactory(key)(region);
		
		const getDOMElementLength:Function = function(xml:XML):int {
			return xml.elements().length();
		};
		
		const updatesWithoutChildren:IObservable = updates.filter(sequence(
			getDOMElementLength,
			partial(eq, 0)
		));
		
		const visibleElementAsWindows:IObservable /*<XML>*/ = updates.
			combineLatest(viewports, args).
			// Only accept updates when the latest DOMElement has children
			filter(distribute(sequence(I, not(sequence(
				getDOMElementLength,
				partial(eq, 0)
			))))).
			// Map all children to a list of visible children, starting with
			// previously cached children
			map(distribute(partial(visibleElements, _, _, cache))).
			takeUntil(updates.count());
		
		const groupLifetimes:Function = globalElementLifetimes(viewports, cache);
		// Map the visible children to a list of lifetime Observables
		const elementLifetimeWindows:IObservable = visibleElementAsWindows.
			map(groupLifetimes);
		
		// Map the lifetime Observables to a list of DOMElements for caching
		const domElementWindows:IConnectableObservable/*<XML>*/ = elementLifetimeWindows.
			map(partial(domElements, _, DOMElement.cache)).
			publish();
		
		// Map each DOMElement to a render function that watches the DOM and
		// returns an IObserveable<Rendered>
		const renderedDOMElementWindows:IObservable = domElementWindows.
			map(function(window:IObservable):IObservable {
				return window.map(function(element:DOMElement):IObservable {
					return childFactory(element.key)(region, element, uiFactory, childFactory, styles);
				});
			});
		
		const childUpdates:IObservable = renderedDOMElementWindows.
			switchMany(callProperty('peekWith', createChildrenObserver(ui)));
		
		const elementsHaveRendered:IObservable = domElementWindows.
			switchMany(function(window:IObservable):IObservable {
				return window.
					map(getProperty('rendered')).
					toArray().
					mapMany(Observable.forkJoin);
			});
		
		const regionStyleables:IObservable = updates.combineLatest(styles, toStyleable);
		const readyToRender:IObservable = updatesWithoutChildren.merge(elementsHaveRendered);
		
		const subscriptions:CompositeCancelable = new CompositeCancelable([
			
			// Apply styles to the region
			regionStyleables.subscribe(region.mergeWith),
			
			// If the new node doesn't have any children, dispatch a render
			// event immediately.
			// 
			// When all the render Observables in a given window have completed
			// dispatch a "render" event on the UI.
			readyToRender.subscribe(sequence(renderEvent, ui.dispatchEvent)),
			
			// Bind the children lifetimes to the UI container's display list
			childUpdates.subscribe(noop, cancelChildSubscriptions),
		]);
		
		updates.subscribe(
			noop,
			printAndCancel(subscriptions, printComplete, 'render_container'),
			printAndCancel(subscriptions, printError, 'render_container')
		);
		
		subscriptions.add(domElementWindows.connect());
		
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
		childSubscriptions[child] = child.
			finallyAction(function():void {
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
		
		container.addChildAt(rendered.display, Math.min(index, container.numChildren));
	};
	
	return Observer.create(next, complete, printError('child rendering'));
}

//internal function compareNodes(a:Array, b:Array):Boolean {
//	if(!a && b) return false;
//	if(!b) return true;
//	
//	// Return true if the arrays contain the same values. Do this by
//	// serializing the Arrays to Strings and comparing the strings.
//	return (
//		(a.length != b.length) ||
//		map(a, toInheritanceChain).join('') === map(b, toInheritanceChain).join('')
//	);
//}

