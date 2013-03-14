package org.tinytlf.streams
{
	import asx.fn.getProperty;
	import asx.fn.sequence;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	
	import raix.reactive.IObservable;

	/**
	 * @author ptaylor
	 */
	public function groupRenderableLifetimes(source:IObservable, /*<Renderable>*/
											 viewport:IObservable,
											 layout:IObservable):IObservable {
		return source.groupByUntil(
			sequence(getProperty('node'), toInheritanceChain),
			filterXMLLifetime(viewport, layout)
		);
	}
}

import flash.geom.Rectangle;

import asx.array.detect;
import asx.fn._;
import asx.fn.areEqual;
import asx.fn.args;
import asx.fn.distribute;
import asx.fn.getProperty;
import asx.fn.partial;
import asx.fn.sequence;

import org.tinytlf.enum.TextBlockProgression;
import org.tinytlf.types.CSS;

import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.Observable;

import trxcllnt.ds.RTree;

internal function filterXMLLifetime(viewport:IObservable, layout:IObservable):Function {
	return function(group:IGroupedObservable):IObservable {
		
		// Dispatch if the node is empty or has been scrolled off screen.
		return Observable.amb([
			// Only dispatch if the node is empty.
			group.filter(sequence(getProperty('node'), nodeIsEmpty)),
			// Only dispatch if the node has been scrolled off screen.
			nodeScrolledOffScreen(String(group.key), viewport, layout)
		]);
	};
}

internal function nodeScrolledOffScreen(key:String, viewport:IObservable, layout:IObservable):IObservable {
	return viewport.combineLatest(layout, args).filter(distribute(nodeIsVisible(key)));
}

internal function nodeIsVisible(key:String):Function {
	return function(viewport:Rectangle, tree:RTree):Boolean {
		// If the node is in the tree, check its position on the
		// screen. Terminate if it not in the current viewport.
		return (tree.find(key) != null) && detect(
			tree.intersections(viewport),
			sequence(getProperty('element'), partial(areEqual, key, _))
		);
	}
}

internal function nodeIsEmpty(node:XML):Boolean {
	return node.toString() == '' && node.text().toString() == '';
}
