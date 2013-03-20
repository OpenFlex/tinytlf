package org.tinytlf.subscriptions
{
	import flash.display.DisplayObjectContainer;
	
	import asx.fn.K;
	import asx.fn.aritize;
	import asx.fn.callFunction;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.newInstance_;
	
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.Renderable;
	import org.tinytlf.types.Rendered;
	
	import raix.reactive.ICancelable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function listenForUIRendered(ui:DisplayObjectContainer, cache:RTree, renderable:Renderable):ICancelable {
		const node:XML = renderable.node;
		const nodeKey:String = toInheritanceChain(node);
		const renderedSubj:ISubject = renderable.rendered;
		
		// When the UI dispatches the 'rendered' event...
		return Observable.fromEvent(ui, renderedEvent().type).
			// ...take just the first occurrence...
			first().
			// ...map it into a new Rendered value...
			map(aritize(partial(newInstance_, Rendered, node, ui), 0)).
			// ...insert the UI into the tree if it hasn't been there before...
			peek(sequence(
				aritize(sequence(K(newInstance_), callFunction(Envelope, ui)), 0),
				aritize(partial(cache.setSize, nodeKey), 2)
			)).
			subscribe(sequence(
				// ...pass the Rendered instance to the rendered Subject's onNext()...
				renderedSubj.onNext,
				// ...then complete the rendered Subject. This pass is done!
				aritize(renderedSubj.onCompleted, 0)
			));
	}
}