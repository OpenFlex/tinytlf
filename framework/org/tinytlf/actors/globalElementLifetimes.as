package org.tinytlf.actors
{
	import asx.fn.partial;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.observables.globalGroupByUntil;
	
	import raix.reactive.IObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function globalElementLifetimes(viewports:IObservable/*<Rectangle>*/,
										   cache:RTree):Function {
		
		const keySelector:Function = toInheritanceChain;
		const durationSelector:Function = partial(filterNodeLifetime, viewports, cache);
		
		return function(elements:IObservable/*[visible] <XML>*/):IObservable/*[visible] <IGroupedObservable>*/ {
			return globalGroupByUntil(elements, keySelector, durationSelector);
		};
	}
}

import flash.geom.Rectangle;
import flash.utils.Dictionary;

import asx.array.detect;
import asx.array.pluck;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.getProperty;
import asx.fn.partial;
import asx.fn.sequence;

import org.tinytlf.handlers.printComplete;
import org.tinytlf.handlers.printError;
import org.tinytlf.handlers.printNext;
import org.tinytlf.lambdas.toInheritanceChain;

import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.ds.RTree;

internal const lifetimes:Dictionary = new Dictionary();

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
	
	const keyIsCached:Boolean = detect(cache.values(), sequence(
		getProperty('element'),
		getProperty('key'),
		partial(areEqual, key)
	));
	
	if(keyIsCached == false) return false;
	
	const keys:Array = pluck(cache.intersections(viewport), 'element.key');
	const keyInKeys:Boolean = detect(keys, partial(areEqual, key));
	
	return keyInKeys == false;
}
