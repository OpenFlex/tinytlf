package org.tinytlf.actors
{
	import flash.display.DisplayObjectContainer;
	
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.partial;
	
	import org.tinytlf.lambdas.sideEffect;
	import org.tinytlf.subscriptions.listenForUIRendered;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;

	/**
	 * @author ptaylor
	 */
	public function mapContainerRenderable(region:Region,
										   uiFactory:Function/*(String):Function(Region):DisplayObjectContainer*/,
										   childFactory:Function/*(String):Function(Region, Function, Function, IObservable<CSS>, IGroupedObservable<Renderable>):IObservable<Rendered>*/,
										   styles:IObservable/*<CSS>*/,
										   lifetime:IGroupedObservable/*<Renderable>*/):IObservable/*<Rendered>*/ {
		
		// Initialize a persistent source subject for XML so the grouping
		// function persists the cache.
		const source:ISubject = new Subject();
		
		// Initialize a region to represent this area in the UI hierarchy.
		// This isn't an actual UI, it's just a collection of observable
		// properties. This is to decouple the UI rendering from tinytlf's
		// internal representation, allowing us to skin the UI however we please.
//		const region:Region = new Region(parent.vScroll, parent.hScroll);
		
		// Call out to initialize a UI component for this renderable region.
		// The only UI logic tinytlf handles itself is binding the list of child
		// UI elements to the display list of this container. The rest of the
		// presentation is up to this UI element, including child layout and scrolling.
		const ui:DisplayObjectContainer = uiFactory(lifetime.key)(region);
		
		// Initialize a persistent Observable that watches the source XML subject
		// for child XML nodes. Key off the region's viewport and layout tree,
		// because the region will be notified when it's been scrolled past.
		// This allows us to genericize the virtualization logic to show/hide
		// children inside this container even though the container may not be
		// entirely out of view itself.
		const visibleChildren:IObservable = emitVisibleRenderables(source, region.viewport, region.cache).
			publish().refCount();
		
		// Initialize a persistent grouping Observable to capture the lifetimes
		// of visible XML nodes. This ensures nodes are transformed into
		// Observable sequences that complete when they're deleted (in edit
		// operations), or scrolled out of view.
		const childLifetimes:IObservable =
			groupRenderableLifetimes(visibleChildren, region.viewport, region.cache).
			publish().
			refCount();
		
		// Initialize a persistent Observable that maps XML lifecycles to
		// asynchronously rendered UI elements.
		const childRenderings:IObservable = childLifetimes.map(function(life:IGroupedObservable):IObservable {
			return childFactory(life.key)(region, uiFactory, childFactory, styles, life);
		});
		
		const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		subscriptions.add(bindChildren(ui, region.cache, childRenderings));
		
		// Return an Observable that maps DOM, style, and layout cache updates
		// to produce the rendering lifecycle of this DOM node and all its
		// children.
		return lifetime.combineLatest(styles, args).
			// Prepare this UI element for rendering...
			peek(distribute(partial(setupUIForRendering, ui, region))).
			// ...and listen for when it's finished...
			peek(distribute(sideEffect(partial(listenForUIRendered, ui, region.cache), subscriptions))).
			// ... then emit the XML's child nodes on the shared source Subject...
			peek(distribute(sideEffect(partial(emitChildNodes, source), subscriptions))).
			// ...map the combinations into an Observable of Observables that
			// represents the rendering lifecycle of this DOM node and its
			// children. If another value is emitted from the lifetime
			// Observable, be sure to cancel any subscriptions to the pending
			// rendering lifecycle.
			switchMany(distribute(partial(mapRenderingLifetime, ui, visibleChildren))).
			// Keep emitting updates until the lifetime sequence terminates.
			takeUntil(lifetime.count()).
			// When this sequence terminates, clean up the child subscriptions.
			finallyAction(subscriptions.cancel);
	}
}
import flash.display.DisplayObjectContainer;

import asx.fn.K;
import asx.fn._;
import asx.fn.aritize;
import asx.fn.getProperty;
import asx.fn.ifElse;
import asx.fn.noop;
import asx.fn.partial;
import asx.fn.sequence;

import org.tinytlf.events.renderEvent;
import org.tinytlf.lambdas.toStyleable;
import org.tinytlf.procedures.applyNodeInheritance;
import org.tinytlf.actors.elementsOfXML;
import org.tinytlf.types.CSS;
import org.tinytlf.types.Region;
import org.tinytlf.types.Renderable;
import org.tinytlf.types.Rendered;

import raix.reactive.CompositeCancelable;
import raix.reactive.ICancelable;
import raix.reactive.IObservable;
import raix.reactive.ISubject;
import raix.reactive.Observable;
import raix.reactive.scheduling.Scheduler;

import trxcllnt.ds.RTree;

internal function setupUIForRendering(ui:DisplayObjectContainer, region:Region, renderable:Renderable, css:CSS):void {
	// Merge the region's styles with styles from the current Style root.
	region.mergeWith(toStyleable(renderable.node, css));
	
	// TODO: This is a hack. Figure out how not to do this.
	ui.removeChildren();
}

internal function emitChildNodes(source:ISubject, renderable:Renderable, css:CSS):ICancelable {
	// Send the node's children to the source Subject. Dispatch the
	// iterateXMLChildren Observable on the greenThread scheduler to allow
	// subscriptions to the visibleChildren Observable to process before the
	// children are sent to the actors.
	return elementsOfXML(renderable.node, Scheduler.greenThread).
		map(applyNodeInheritance).
		// Ignore when the iteration has completed.
		concat(Observable.never()).
		// Pipe the children through the shared source Subject...
		multicast(source).
		// ...and go!
		connect();
}

internal function mapRenderingLifetime(container:DisplayObjectContainer, visibleChildren:IObservable, renderable:Renderable, css:CSS):IObservable {
	const node:XML = renderable.node;
	const rendered:ISubject = renderable.rendered;
	const numChildren:int = node.elements().length();
	
	// If there aren't any children, wait until this UI element has finished.
	if(numChildren <= 0) {
		// Tell the UI to render itself.
		container.dispatchEvent(renderEvent());
		return rendered.asObservable();
	}
	
	// Select the 'rendered' Subject from the visibleChildren values...
	return visibleChildren.map(getProperty('rendered')).
		// ...but only as many as are about to be emitted from the
		// shared source Subject. Combine them all into one list...
		bufferWithCount(numChildren).
		// ...complete after the buffer is done...
		take(1).
		// ...wait until the've all completed...
		mapMany(Observable.forkJoin).
		// Tell the UI to render itself. Do this after the children have rendered!
		peek(sequence(K(renderEvent()), container.dispatchEvent)).
		// ...and emit this UI's Rendered value!
		mapMany(K(rendered)).
		concat(Observable.never());
}

internal function bindChildren(container:DisplayObjectContainer,
							   cache:RTree,
							   childLifetimes:IObservable):ICancelable {
	
	const subscriptions:CompositeCancelable = new CompositeCancelable();
	
	const outer:ICancelable = childLifetimes.subscribe(partial(
		observeChildLifetime, container, cache, _, subscriptions
	));
	
	subscriptions.add(outer);
	
	return subscriptions;
}

internal function observeChildLifetime(container:DisplayObjectContainer,
									   cache:RTree,
									   lifetime:IObservable,
									   subscriptions:CompositeCancelable):void {
	
	var removeChild:Function = noop;
	
	const childRemoved:Function = function():void {
		removeChild();
		subscription.cancel();
		subscriptions.remove(subscription);
	};
	
	const updateRemoveChild:Function = function(rendered:Rendered):void {
		removeChild = ifElse(
			partial(container.contains, rendered.display),
			partial(container.removeChild, rendered.display),
			noop
		);
	};
	
	const childUpdated:Function = function(rendered:Rendered):void {
		// TODO: Real virtualization based on the RTree cache.
		container.addChild(rendered.display);
	};
	
	const subscription:ICancelable = lifetime.
		peek(updateRemoveChild).
		subscribe(childUpdated, childRemoved, aritize(childRemoved, 0));
	
	subscriptions.add(subscription);
}


























