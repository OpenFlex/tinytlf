package org.tinytlf.parsers.inline
{
	import flash.text.engine.ElementFormat;
	import flash.text.engine.TextElement;
	
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;

	/**
	 * @author ptaylor
	 */
	public function br_inline(element:Values):IObservable {
		
		const rendered:ISubject = new BehaviorSubject();
		
		element.combine('*').map(function(...args):Array {
			return [element, new TextElement('\n', new ElementFormat())];
		}).
		subscribeWith(rendered);
		
		return rendered;
	}
}