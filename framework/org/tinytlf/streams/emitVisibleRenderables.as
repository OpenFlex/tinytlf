package org.tinytlf.streams
{
	import asx.array.pluck;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Plan;
	import raix.reactive.subjects.IConnectableObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function emitVisibleRenderables(source:IObservable,
										   viewport:IObservable,
										   cache:RTree):IObservable {
		
		const terminated:IConnectableObservable = source.count().peek(trace).publish();
		terminated.connect();
		
		// Terminate if the source Observable terminates. 
		viewport = viewport.takeUntil(terminated);
		
		// Listen for changes from the viewport.
		const distinctKeysStream:IObservable = viewport.map(cache.intersections).
			map(partial(pluck, _, 'element')).
			// When they change, pull the visible XML node keys from the tree.
			// But only notify if the visible nodes have changed since we last rendered.
			distinctUntilChanged(compareNodeKeys).
			// wrap the keys Array in another Array.
			map(partial(newInstance_, Array));
		
		// Update the nodes when the distinctKeysStream emits a value and
		// combine the keys with the present viewport and layout values.
		const updateNodesPlan:Plan = distinctKeysStream.and(viewport).then(args);
		
		return Observable.when([updateNodesPlan]).
			// If the visible keys did change, build and subscribe to an
			// Observable that enumerates the nodes in the order they should be
			// rendered. In case we're in the middle of this process already,
			// switchMany terminates the subscription to the previous
			// (now invalid) XML Observable.
			switchMany(distribute(partial(selectVisibleNodes, source, _, _, cache))).
			// When the source terminates, clear out the XML cache.
			finallyAction(cleanUpXMLCache);
	}
}

import flash.geom.Rectangle;

import org.tinytlf.lambdas.toInheritanceChain;
import org.tinytlf.types.Renderable;

import raix.reactive.IObservable;
import raix.reactive.Observable;
import raix.reactive.toObservable;

import trxcllnt.ds.RTree;

internal function selectVisibleNodes(source:IObservable, keys:Array, dimensions:Rectangle, cache:RTree):IObservable {
	source = source.
		// always cache the xml nodes
		peek(cacheNode).
		// only emit enough nodes to fill up to the current
		// size of the viewport.
		takeWhile(function(node:XML):Boolean {
			const env:Rectangle = cache.envelope;
			return (env.bottom * env.right) <= (dimensions.bottom * dimensions.right);
		});
	
	// If there are keys, use them first. when those
	// run out, use nodes from the xml source.
	const nodes:IObservable = keys.length > 0 ?
		toObservable(keys).map(keyToNode).concat(source) :
		source;
	
	// Queue the xml nodes, dispatch one at a time,
	// wait until its done rendering to dispatch another one.
	// This allows us to check bounds and only dispatch nodes that
	// are within view.
	return nodes.concatMany(function(node:XML):IObservable {
			const renderable:Renderable = new Renderable(node);
			return Observable.value(renderable).takeUntil(renderable.rendered);
		}).
		// Don't allow this Observable to complete because it'll trigger
		// unwanted unsubscriptions.
		concat(Observable.never());
}

internal function compareNodeKeys(prevKeys:Array, nextKeys:Array):Boolean {
	if(!prevKeys && nextKeys) return false;
	if(prevKeys && !nextKeys) return true;
	// Return true if the arrays contain the same values.
	return prevKeys.join('') == nextKeys.join('');
}

internal var nodeCache:Object = {};

internal function keyToNode(key:String):XML {
	return nodeCache[key];
}

internal function cacheNode(node:XML):void {
	nodeCache[toInheritanceChain(node)] = node;
}

internal function cleanUpXMLCache():void {
	nodeCache = {};
}