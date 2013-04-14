package org.tinytlf.actors
{
	import asx.fn.*;
	import asx.object.*;
	
	import flash.display.*;
	
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.types.*;
	
	import raix.reactive.*;

	/**
	 * @author ptaylor
	 */
	public function correlateUpdatesAndRenderedEvents(updates:IObservable/*<XML>*/,
													  dom:DOMElement,
													  viewports:IObservable, 
													  ui:DisplayObjectContainer):IObservable {
		
		// Listen for the "rendered" event from the UI
		const uiRendered:IObservable = Observable.fromEvent(ui, renderedEvent().type).
			takeUntil(dom.count());
		
		// Build a function that accepts an XML node and instantiates a new 'Rendered' instance.
		const mapRendered:Function = partial(aritize(newInstance_, 3), Rendered, _, ui);
		
		// Subscribe to the result of uiRendered.map(node), but only while the node
		// is the latest value. When the UI dispatches the 'rendered' Event, the
		// latest node is returned and passed to mapRendered, creating the most
		// recent Rendered instance.
		
		return updates.combineLatest(viewports, I).
			switchMany(sequence(K(dom), K, uiRendered.map)).
			map(mapRendered).
			takeUntil(dom.count());
	}
}