package org.tinytlf.parsers.inline
{
	import asx.array.last;
	import asx.array.map;
	import asx.fn.callProperty;
	import asx.fn.sequence;
	
	import flash.text.engine.ContentElement;
	import flash.text.engine.GroupElement;
	
	import org.tinytlf.enumerables.generateFromXMLList;
	import org.tinytlf.fn.toElementFormat;
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;

	/**
	 * @author ptaylor
	 */
	public function span(render:Function,
						 values:Values):IObservable /*Array<Values, GroupElement>*/ {
		
		const rendered:ISubject = new BehaviorSubject();
		
		values.combine('*').
			switchMany(function(...args):IObservable /*Array<Values, GroupElement>*/ {
				const html:XML = values.html;
				const children:XMLList = html.*;
				
				return generateFromXMLList(children, 0).
					map(sequence(mapValues, render, callProperty('take', 1))).
					concatMany().
					toArray().
					map(function(children:Array):Array {
						const contents:Array = map(children, last);
						const elements:Vector.<ContentElement> = Vector.<ContentElement>(contents);
						return [values, new GroupElement(elements, toElementFormat(values))];
					});
			}).
			multicast(rendered).
			connect();
		
		return rendered;
	}
}

import org.tinytlf.fn.addInheritanceChain;
import org.tinytlf.fn.toInheritanceChain;
import org.tinytlf.fn.wrapTextNodes;
import org.tinytlf.observables.Values;

internal function mapValues(node:XML):Values {
	return new Values({
		index: node.childIndex(),
		html: wrapTextNodes(addInheritanceChain(node)),
		key: toInheritanceChain(node)
	}, 'html');
}