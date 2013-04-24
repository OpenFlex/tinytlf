package org.tinytlf.enumerables
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.observables.Values;
	
	import raix.interactive.IEnumerable;
	import raix.interactive.toEnumerable;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function visibleValues(list:XMLList,
								  start:int,
								  end:int,
								  cache:Virtualizer):IEnumerable/*[visible] <Values>*/ {
		
		const cached:IEnumerable = toEnumerable(cachedValues(start, end, cache));
		
		// TODO: What if an element was inserted between two cached elements?
		
		const last:Values = cached.lastOrDefault() as Values;
		const start:int = last == null ? 0 : last.index;
		
		const rest:IEnumerable =  generateFromXMLList(list, start).map(valuesFromXML);
		
		return cached.skipLast(1).concat(rest);
	}
}

import flash.geom.Rectangle;

import org.tinytlf.fn.addInheritanceChain;
import org.tinytlf.fn.toInheritanceChain;
import org.tinytlf.fn.wrapTextNodes;
import org.tinytlf.observables.Values;

import trxcllnt.vr.Virtualizer;

internal function valuesFromXML(node:XML):Values {
	return new Values({
		cache: new Virtualizer(),
		index: node.childIndex(),
		html: wrapTextNodes(addInheritanceChain(node)),
		key: toInheritanceChain(node),
		viewport: new Rectangle()
	}, 'cache', 'html', 'viewport', 'width', 'height', 'x', 'y');
};