package org.tinytlf.renderers
{
	import asx.array.first;
	import asx.array.map;
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.fn.tap;
	import asx.object.newInstance_;
	
	import flash.text.engine.ContentElement;
	import flash.text.engine.GroupElement;
	import flash.text.engine.TextElement;
	
	import org.tinytlf.lambdas.toElementFormat;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMNode;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function content(childFactory:Function, node:DOMNode, root:CSS):IObservable {
		
		const name:String = node.name;
		const children:Array = node.children;
		
		if(children.length == 0) {
			const element:ContentElement = (
				childFactory(name)(node) ||
				new TextElement(node.value, toElementFormat(node))
			);
			
			return Observable.value(element);
		}
		
		// Use a dummy node to recursively call the content function without
		// wasting resources creating short-lived DOMNodes.
		const childObservables:Array = map(node.children, sequence(
			partial(dummy.update, _, root),
			partial(content, childFactory, _, root),
			tap(aritize(dummy.clearStyles, 0), _)
		));
		
		const rendered:IObservable = childObservables.length == 1 ?
			IObservable(first(childObservables)).map(partial(newInstance_, Array)) :
			Observable.forkJoin(childObservables);
		
		return rendered.map(function(elements:Array):Vector.<ContentElement> {
				return Vector.<ContentElement>(elements);
			}).
			map(partial(newInstance_, GroupElement, _, toElementFormat(node)));
	}
}
import org.tinytlf.types.DOMNode;

internal const dummy:DOMNode = new DOMNode(<_/>);