package org.tinytlf.streams
{
	import flash.display.DisplayObjectContainer;
	
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.partial;
	
	import org.tinytlf.lambdas.sideEffect;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;

	/**
	 * @author ptaylor
	 */
	public function mapContainerRenderable(parent:Region,
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
		const region:Region = new Region(parent.vScroll, parent.hScroll);
		
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
		return lifetime.
			combineLatest(styles, args).
			combineLatest(region.cache, args).
			// Prepare this UI element for rendering...
			peek(distribute(partial(setupUIForRendering, ui, region))).
			// ...and listen for when it's finished...
			peek(distribute(sideEffect(partial(listenForUIRendered, ui), subscriptions))).
			// ... then emit the XML's child nodes on the shared source Subject...
			peek(distribute(sideEffect(partial(emitChildNodes, source), subscriptions))).
			// ...map the combinations into an Observable of Observables that
			// represents the rendering lifecycle of this DOM node and its
			// children. If another value is emitted from the lifetime
			// Observable, be sure to cancel any subscriptions to the pending
			// rendering lifecycle.
			switchMany(distribute(partial(mapRenderingLifetime, visibleChildren))).
			// Keep emitting updates until the lifetime sequence terminates.
			takeUntil(lifetime.count()).
			// When this sequence terminates, clean up the child subscriptions.
			finallyAction(subscriptions.cancel);
	}
}
import flash.display.DisplayObjectContainer;
import flash.events.Event;

import asx.array.first;
import asx.fn.K;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.args;
import asx.fn.aritize;
import asx.fn.distribute;
import asx.fn.getProperty;
import asx.fn.guard;
import asx.fn.ifElse;
import asx.fn.noop;
import asx.fn.partial;
import asx.fn.sequence;
import asx.object.newInstance_;

import org.tinytlf.lambdas.toInheritanceChain;
import org.tinytlf.lambdas.toStyleable;
import org.tinytlf.streams.iterateXMLChildren;
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

import trxcllnt.ds.Envelope;
import trxcllnt.ds.RTree;

internal function setupUIForRendering(ui:DisplayObjectContainer, region:Region, renderable:Renderable, css:CSS, tree:RTree):void {
	// Merge the region's styles with styles from the current Style root.
	region.mergeWith(toStyleable(renderable.node, css));
	
	// Tell the UI to render itself!
	ui.dispatchEvent(new Event('render'));
	
	// TODO: This is a hack. Figure out how not to do this.
	ui.removeChildren();
}

internal function listenForUIRendered(ui:DisplayObjectContainer, renderable:Renderable, css:CSS, tree:RTree):ICancelable {
	const node:XML = renderable.node;
	const nodeKey:String = toInheritanceChain(node);
	const rendered:ISubject = renderable.rendered;
	
	// When the UI dispatches the 'rendered' event...
	return Observable.fromEvent(ui, 'rendered').
		// ...take just the first occurrence...
		first().
		// ...map it into a new Rendered value...
		map(partial(newInstance_, Rendered, node, ui)).
		// ...insert the UI into the tree if it hasn't been there before...
		peek(ifElse(
			sequence(K(tree.find(nodeKey)), partial(areEqual, null)),
			partial(aritize(tree.insert, 2), nodeKey, new Envelope(ui)),
			noop
		)).
		subscribe(sequence(
			// ...pass the Rendered instance to the Subject's onNext()...
			rendered.onNext,
			// ...then complete the rendered subject. This pass is done!
			guard(rendered.onCompleted)
		));
}

internal function emitChildNodes(source:ISubject, renderable:Renderable, css:CSS, tree:RTree):ICancelable {
	// Send the node's children to the source Subject.
	return iterateXMLChildren(renderable.node).
		// Ignore when the iteration has completed.
		concat(Observable.never()).
		// ...but subscribe to the iterateXMLChildren Observable on the
		// greenThread scheduler to allow subscriptions to the
		// visibleChildren Observable to process before the children
		// are sent to the actors.
		subscribeOn(Scheduler.greenThread).
		// Pipe the children through the shared source Subject...
		multicast(source).
		// ...and go!
		connect();
}

internal function mapRenderingLifetime(visibleChildren:IObservable, renderable:Renderable, css:CSS, tree:RTree):IObservable {
	const node:XML = renderable.node;
	const rendered:ISubject = renderable.rendered;
	const numChildren:int = node.*.length();
	
	// If there aren't any children, wait until this UI element has finished.
	if(numChildren <= 0) return rendered.asObservable();
	
	// Select the 'rendered' Subject from the visibleChildren values...
	return visibleChildren.map(getProperty('rendered')).
		// ...but only as many as are about to be emitted from the
		// shared source Subject...
		take(numChildren).
		// ...combine them all into one list...
		bufferWithCount(numChildren).
		// ...and append this UI's rendered Subject to the list...
		map(partial(args, rendered)).
		// ...wait until the've all completed...
		mapMany(Observable.forkJoin).
		// ...and emit just this UI's Rendered value!
		map(first);
}

internal function bindChildren(container:DisplayObjectContainer,
							   cache:IObservable,
							   childLifetimes:IObservable):ICancelable {
	
	const subscriptions:CompositeCancelable = new CompositeCancelable();
	
	const combination:IObservable = cache.combineLatest(childLifetimes, args);
	const outer:ICancelable = combination.subscribe(sequence(
		distribute(partial(observeChildLifetime, container, _, _, subscriptions)),
		subscriptions.add
	));
	
	subscriptions.add(outer);
	
	return subscriptions;
}

internal function observeChildLifetime(container:DisplayObjectContainer,
									   tree:RTree,
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
}


























