package org.tinytlf.parsers
{
	import asx.array.detect;
	import asx.array.filter;
	import asx.array.max;
	import asx.fn.I;
	import asx.fn.K;
	import asx.fn._;
	import asx.fn.callProperty;
	import asx.fn.apply;
	import asx.fn.getProperty;
	import asx.fn.noop;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.DOMNode;
	import org.tinytlf.types.Region;
	import org.tinytlf.views.Container;
	
	import raix.interactive.toEnumerable;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	public function head(element:DOMElement/*<DOMNode>*/,
						 uiFactory:Function,
						 parserFactory:Function):IObservable/*Array<DOMElement, DisplayObject>*/ {
		
		const region:Region = element.region;
		
		const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		// TODO: This shares a surprising amount of logic with the container
		// virtualization rendering. Abstract both of these into some common algo.
		const styles:Object = {};
		const selectStyles:Function = sequence(
			getProperty('elements'),
			partial(filter, _, filterLocalName('style')),
			toEnumerable,
			callProperty('map', mapNodesToDOMElements(DOMElement.cache)),
			callProperty('map', mapDOMElementUpdates(styles, uiFactory, parserFactory, subscriptions)),
			callProperty('map', getProperty('rendered')),
			callProperty('concatMany')
		);
		
		const stylesObs:IObservable = virtualize(element, element, selectStyles, noop, K(Observable.value([element])));
		
		const body:DOMElement = new DOMElement(region, 'body');
		
		const bodyObs:IObservable = container(body, uiFactory, parserFactory);
		const bodySubscription:ICancelable = element.map(function(head:DOMNode):DOMNode {
			return new DOMNode(detect(head.elements, filterLocalName('body')) as XML, uiFactory('css')());
		}).
		subscribe(body.update);
		
		subscriptions.add(bodySubscription);
		
		return bodyObs.combineLatest(stylesObs, I).
			map(apply(function(body:DOMElement, child:Container):Array {
				
				// TODO: Update this when I use an RTree.
				region.width = max(child.children, 'width') as Number;
				region.height = region.cache.size;
				
				return [element, child];
			}));
	}
}
import asx.array.filter;
import asx.fn.noop;

import org.tinytlf.lambdas.toInheritanceChain;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.DOMNode;
import org.tinytlf.types.Region;

import raix.reactive.CompositeCancelable;
import raix.reactive.ICancelable;
import raix.reactive.IObservable;
import raix.reactive.Observable;

internal function filterLocalName(name:String):Function {
	return function(node:XML):Boolean {
		return node.localName() == name;
	};
};

internal function mapNodesToDOMElements(elements:Object):Function {
	return function(node:XML):DOMElement {
		
		const key:String = toInheritanceChain(node);
		
		return elements[key] ||= new DOMElement(
			new Region(Observable.empty(), Observable.empty()),
			key,
			new DOMNode(node)
		);
	};
};

internal function mapDOMElementUpdates(styles:Object,
									   uiFactory:Function,
									   parserFactory:Function,
									   subscriptions:CompositeCancelable):Function {
	
	return function(style:DOMElement):DOMElement {
		const key:String = style.key;
		
		if(styles.hasOwnProperty(key)) {
			return style.update(style.node);
		}
		
		const completed:Function = function(...args):void {
			delete styles[key];
			style.onCompleted();
			
			lifetimeSubscription.cancel();
			subscriptions.remove(lifetimeSubscription);
		};
		
		const parser:Function = parserFactory(key);
		const lifetime:IObservable = parser(style, uiFactory, parserFactory);
		const lifetimeSubscription:ICancelable = lifetime.subscribe(noop, completed, completed);
		
		return styles[key] = style;
	};
}

