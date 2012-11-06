package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function char(target:IEventDispatcher):IObservable {
		return keydown(target).filter(function(event:KeyboardEvent):Boolean {
			return event.keyCode >= Keyboard.A && event.keyCode <= Keyboard.Z;
		});
	}
}