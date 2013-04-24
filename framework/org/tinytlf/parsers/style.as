package org.tinytlf.parsers
{
	import asx.fn.noop;
	import asx.fn.partial;
	
	import org.tinytlf.handlers.printError;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.DOMNode;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.scheduling.Scheduler;

	/**
	 * @author ptaylor
	 */
	public function style(element:DOMElement/*<DOMNode>*/,
						  uiFactory:Function,
						  parserFactory:Function):IObservable/*Array<DOMElement, null>*/ {
		
		const rendered:ISubject = element.rendered;
		const global:CSS = uiFactory(element.key)();
		
		// TODO: asynchronously update the global CSS cache
		return element.peek(function(node:DOMNode):void {
			global.inject(node.value);
		}).peek(
			function(...args):void {
				Scheduler.defaultScheduler.schedule(partial(rendered.onNext, [element, null]));
				Scheduler.defaultScheduler.schedule(rendered.onCompleted);
			},
			noop,
			printError('style: ' + element.key, true)
		);
	}
}
