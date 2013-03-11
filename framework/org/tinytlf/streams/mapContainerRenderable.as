package org.tinytlf.streams
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	
	import org.tinytlf.lambdas.deriveNodeInheritance;
	import org.tinytlf.lambdas.toStyleable;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Renderable;
	import org.tinytlf.types.Rendered;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	
	import trxcllnt.ds.RTree;

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
		const visibleChildren:IObservable = emitVisibleRenderables(source, region.viewport, region.layoutCache);
		
		// Initialize a persistent grouping Observable to capture the lifetimes
		// of visible XML nodes. This ensures nodes are transformed into
		// Observable sequences that complete when they're deleted (in edit
		// operations), or scrolled out of view.
		const childLifetimes:IObservable = 
			groupRenderableLifetimes(visibleChildren, region.viewport, region.layoutCache).
			publish().
			refCount();
		
		// Initialize a persistent Observable that maps XML lifecycles to
		// asynchronously rendered UI elements.
		const childRenderings:IObservable = childLifetimes.map(function(life:IGroupedObservable):IObservable {
			return childFactory(life.key)(region, uiFactory, childFactory, styles, life);
		});
		
		const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		// Bind the children UIs to the container UI.
		subscriptions.add(
			region.layoutCache.
			combineLatest(childRenderings, args).
			subscribe(distribute(function(tree:RTree, rendering:IObservable):void {
				
				var nodeKey:String = '';
				var child:DisplayObject;
				
				// Observe the rendering lifecycle. Insert the rendered child at the
				// correct index represented by the XML node on updates.
				const childSubscription:ICancelable = rendering.subscribe(
					function(rendered:Rendered):void {
						const node:XML = rendered.node;
						const index:int = node.childIndex();
						nodeKey = deriveNodeInheritance(node);
						
						// Add the child to the display list
						ui.addChildAt(child = rendered.display, Math.min(ui.numChildren, index == -1 ? 0 : index));
						
						// Add the child to the region's virtualization cache -- the
						// parent UI component should update the cache during it's
						// render phase.
						tree.insert(nodeKey, new Rectangle(0, 0, 1, 1));
					},
					// Remove the child when the sequence completes.
					function():void {
						if(child && ui.contains(child)) ui.removeChild(child);
						
						childSubscription.cancel();
						subscriptions.remove(childSubscription);
					}
				);
				
				// Track the subscriptions for garbage collection.
				subscriptions.add(childSubscription);
			})));
		
		// Use switchMany to cancel ongoing inner activity when a new lifetime
		// is emitted before the inner sequences have completed.
		return lifetime.
			combineLatest(styles, args).
			switchMany(distribute(function(renderable:Renderable, css:CSS):IObservable {
				
				const node:XML = renderable.node;
				const numChildren:int = node.*.length();
				const rendered:ISubject = renderable.rendered;
				
				// Take the appropriate number of child lifetimes, watch their
				// "rendered" Subjects for completion, then notify our "rendered"
				// Subject of completion.
				const childObs:IObservable = childLifetimes.
					take(numChildren).
					bufferWithCount(numChildren).
					concatMany(function(life:IObservable/*<Renderable>*/):IObservable {
						return life.take(1).map(getProperty('rendered'));
					}).
					switchMany(Observable.forkJoin);
				
				// An Observable that represents a Rendered value.
				const currentObs:IObservable = Observable.
					value(new Rendered(node, ui)).
					peek(function(rendered:Rendered):void {
						// Tell the UI to render itself!
						ui.dispatchEvent(new Event('render'));
					});
				
				// Give this region its styles.
				region.mergeWith(toStyleable(node, css));
				
				// Send the node's children to the source Subject.
				iterateXMLChildren(node).
					concat(Observable.never()).
					subscribeWith(source);
				
				// Return the concatonation of the children and this node's
				// DOM updates.
				return Observable.concat([
					childObs,
					currentObs
			]).
			// When the children and the current Observable have completed,
			// notify our "rendered" Subject.
			finallyAction(rendered.onCompleted).
			// Only take the last value from the concatonation, i.e. the
			// Rendered value.
			takeLast(1);
		})).
		takeUntil(lifetime.count()).
		// When this sequence terminates, clean up the child subscriptions.
		finallyAction(subscriptions.cancel);
	}
}