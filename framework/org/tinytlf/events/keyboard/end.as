package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.env.mac;
	import org.tinytlf.events.modifiers.command;
	
	import raix.reactive.*;

	/**
	 * @author ptaylor
	 */
	public function end(target:IEventDispatcher):IObservable {
		return mac ? command(arrowleft(target)) : keyequals(keydown(target), Keyboard.END);
	}	
}