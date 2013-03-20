package org.tinytlf.actors
{
	import flash.utils.Dictionary;
	
	import asx.fn.K;
	import asx.fn.getProperty;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.newInstance_;
	
	import org.tinytlf.observables.memoize;
	import org.tinytlf.types.DOMElement;
	
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function domElements(groups:IObservable/*[visible] <IGroupedObservable<XML>>*/,
								domElementCache:Dictionary):IObservable/*[visible] <DOMElement>*/ {
		
		return groups.map(function(group:IGroupedObservable):DOMElement {
			
			const element:DOMElement = domElementCache[group.key] || new DOMElement(group.key.toString());
			
			domElementCache[group.key] = element;
			
			element.source = group;
			
			return element;
		}).
		publish().refCount();
	}
}
