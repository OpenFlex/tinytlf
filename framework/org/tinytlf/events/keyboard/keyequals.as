package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function keyequals(obs:IObservable, code:uint):IObservable {
		return obs.filter(function(event:KeyboardEvent):Boolean {
			return event.keyCode == code;
		});
	}
}