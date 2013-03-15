package org.tinytlf.streams
{
	import org.tinytlf.procedures.applyNodeInheritance;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.IScheduler;

	/**
	 * @author ptaylor
	 */
	public function iterateXMLElements(node:XML, scheduler:IScheduler = null):IObservable {
		const children:XMLList = node.elements();
		
		return Observable.generate(
			0,
			function(i:int):Boolean { return i < children.length();},
			function(i:int):int { return i + 1; },
			function(i:int):XML { return children[i]; },
			scheduler
		);
	}
}