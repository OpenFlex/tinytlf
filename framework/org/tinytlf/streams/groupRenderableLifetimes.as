package org.tinytlf.streams
{
	import asx.fn.getProperty;
	import asx.fn.sequence;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	
	import raix.reactive.IObservable;
	
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function groupRenderableLifetimes(source:IObservable, /*<Renderable>*/
											 viewport:IObservable,
											 cache:RTree):IObservable {
		return source.groupByUntil(
			sequence(getProperty('node'), toInheritanceChain),
			filterXMLLifetime(viewport, cache)
		);
	}
}

import flash.geom.Rectangle;

import asx.array.detect;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.getProperty;
import asx.fn.partial;
import asx.fn.sequence;

import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.ds.RTree;

internal function filterXMLLifetime(viewport:IObservable, cache:RTree):Function {
	return function(group:IGroupedObservable):IObservable {
		
		// Dispatch if the node is empty or has been scrolled off screen.
		return Observable.amb([
			// Only dispatch if the node is empty.
			group.filter(sequence(getProperty('node'), nodeIsEmpty)),
			// Only dispatch if the node has been scrolled off screen.
			nodeScrolledOffScreen(String(group.key), viewport, cache)
		]);
	};
}

internal function nodeScrolledOffScreen(key:String, viewport:IObservable, cache:RTree):IObservable {
	return viewport.filter(nodeIsVisible(key, cache));
}

internal function nodeIsVisible(key:String, cache:RTree):Function {
	return function(viewport:Rectangle):Boolean {
		// If the node is in the tree, check its position on the
		// screen. Terminate if it not in the current viewport.
		return (cache.find(key) != null) && detect(
			cache.intersections(viewport),
			sequence(getProperty('element'), partial(areEqual, key, _))
		);
	}
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}
