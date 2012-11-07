package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function arrowup(target:IEventDispatcher):IObservable {
		return keyequals(keydown(target), Keyboard.UP);
	}
}