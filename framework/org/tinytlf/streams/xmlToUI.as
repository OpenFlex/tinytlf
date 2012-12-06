package org.tinytlf.streams
{
	import org.tinytlf.lambdas.applyInheritanceChain;
	import org.tinytlf.fn.identify;
	
	import raix.reactive.*;

	/**
	 * Accepts an XML node and returns an IObservable<DisplayObject> for it.
	 * 
	 * <code>parsers</code> is a Hashtable of functions, where each key
	 * corresponds to the localName() of an XML node. Each function should
	 * accept the node as an argument and return a function which produces an
	 * IObservable<DisplayObject>.
	 * 
	 * If no parser function exists in the dictionary for a node, a default
	 * recursive function is used, where a DisplayObjectContainer is created
	 * for the node, and its children are passed into <code>xmlToUI</code>, then
	 * their DisplayObjects are appended to the container.
	 * 
	 * TODO: Eventually, do some fancy HTML-style default layout with Containers.
	 * 
	 * @author ptaylor
	 */
	public function xmlToUI(node:XML, parsers:Object = null):IObservable//<DisplayObject>
	{
		parsers ||= {};
		node = applyInheritanceChain(node);
		const name:String = node.localName();
		
		const parser:Function = parsers[name] && parsers[name](node);
		const factory:Function = parser || recurse(node, parsers);
		
		return Observable.defer(factory);
	}
}

import flash.display.*;

import org.tinytlf.classes.Container;
import org.tinytlf.fn.identify;
import org.tinytlf.streams.xmlToUI;

import raix.reactive.*;

internal function recurse(node:XML, parsers:Object):Function {
	return function():IObservable/*<DisplayObjectContainer>*/ {
		
		const parent:DisplayObjectContainer = new Container();
		const observables:Array = [];
		
		for each(var child:XML in node.children()) {
			observables.push(
				xmlToUI(child, parsers).
				scan(function(prev:DisplayObject, next:DisplayObject):DisplayObject {
					if(prev && parent.contains(prev)) parent.removeChild(prev);
					return parent.addChildAt(next, child.childIndex());
				}));
		}
		
		const obs:IObservable = observables.length > 1 ?
			Observable.forkJoin(observables) :
			observables.length == 1 ?
			observables[0] :
			Observable.value(node);
		
		return obs.map(identify(parent));
	}
}