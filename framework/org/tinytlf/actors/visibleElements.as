package org.tinytlf.actors
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.partial;
	import asx.number.gt;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.RTree;

	/**
	 * Enumerates the visible cached and fresh children from the input XML node
	 * for the given viewport Rectangle and cache RTree as an IObservable<XML>,
	 * but only while the new viewport area is greather than or equal to the
	 * area of the RTree cache.
	 * 
	 * @author ptaylor
	 */
	public function visibleElements(node:XML, viewport:Rectangle, cache:RTree):IObservable/*<XML>*/ {
		
		const scheduler:IScheduler = Scheduler.greenThread;
		
		const cachedValues:Array = cachedElements(viewport, cache);
		
		const cached:IObservable = Observable.fromArray(cachedValues, scheduler);
		const all:IObservable = elementsOfXML(node, scheduler);
		
		// Theoretically the cache is being updated async by our subscribers.
		// TODO: Compare based on block progression.
		const cacheIsSmallerThanViewport:Function = function(...args):Boolean {
			const envelope:Envelope = cache.envelope; // re-query for the Envelope value
			return envelope.height <= viewport.height;
		};
		
		// Only take new elements that come after cached elements
		const elements:IObservable = cached.concat(cached.
			lastOrDefault().
			mapMany(function(last:XML):IObservable {
				return last == null ?
					all :
					all.filter(partial(gt, _, last.childIndex()));
			}).
			takeWhile(cacheIsSmallerThanViewport));
		
		const distinctCache:Dictionary = new Dictionary();
		
		// Poor man's IObservable.distinct()
		return elements.filter(function(x:XML):Boolean {
				const key:String = toInheritanceChain(x);
//				trace(key);
				return distinctCache.hasOwnProperty(key) ? false : distinctCache[key] = true;
			});
	}
}
