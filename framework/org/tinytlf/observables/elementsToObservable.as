package org.tinytlf.observables
{
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.IScheduler;

	/**
	 * @author ptaylor
	 */
	public function elementsToObservable(node:XML, scheduler:IScheduler = null):IObservable {
		const elements:XMLList = node.elements();
		const numElements:int = elements.length();
		
		return Observable.generate(
			0,
			function(i:int):Boolean { return i < elements.length();},
			function(i:int):int { return i + 1; },
			function(i:int):XML { return elements[i]; },
			scheduler
		);
	}
}