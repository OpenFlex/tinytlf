package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function keydown(target:IEventDispatcher):IObservable {
		return Observable.fromEvent(target, KeyboardEvent.KEY_DOWN);
	}
}