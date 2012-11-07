package org.tinytlf.events.mouse
{
	import flash.events.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function out(target:IEventDispatcher):IObservable {
		return Observable.fromEvent(target, MouseEvent.ROLL_OUT);
	}
}