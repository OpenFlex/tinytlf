package org.tinytlf.parsers.inline
{
	import flash.text.engine.TextElement;
	
	import org.tinytlf.fn.toElementFormat;
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;

	/**
	 * @author ptaylor
	 */
	public function text(values:Values):IObservable /*<Values, ContentElement>*/ {
		
		const rendered:ISubject = new BehaviorSubject();
		
		values.combine('*').
			map(function(...args):Array {
				const html:XML = values.html;
				const text:String = html.text().toString();
				return [values, new TextElement(text, toElementFormat(values))];
			}).
			multicast(rendered).
			connect();
		
		return rendered;
	}
}