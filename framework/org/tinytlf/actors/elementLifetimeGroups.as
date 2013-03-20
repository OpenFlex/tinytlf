package org.tinytlf.actors
{
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.DOMElement;
	
	import raix.reactive.IObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function elementLifetimeGroups(viewports:IObservable/*<Rectangle>*/,
										  elements:IObservable/*[visible] <XML>*/,
										  cache:RTree):IObservable/*[visible] <IGroupedObservable>*/ {
		
		const keySelector:Function = toInheritanceChain;
		const durationSelector:Function = partial(filterNodeLifetime, viewports, cache);
		
		return elements.groupByUntil(keySelector, durationSelector);
	}
}
import flash.geom.Rectangle;

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.partial;

import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.ds.RTree;

internal function filterNodeLifetime(viewports:IObservable,
									 cache:RTree,
									 group:IGroupedObservable):IObservable {
	return Observable.amb([
		group.filter(nodeIsEmpty),
		viewports.filter(partial(nodeScrolledOffScreen, _, group.key, cache))
	]);
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}

internal function nodeScrolledOffScreen(viewport:Rectangle, key:String, cache:RTree):Boolean {
	
	const keyIsCached:Boolean = cache.find(key) != null;
	
	if(keyIsCached == false) return false;
	
	const keys:Array = pluck(cache.intersections(viewport), 'element');
	const keyInKeys:Boolean = detect(keys, partial(areEqual, key));
	
	return keyInKeys;
}