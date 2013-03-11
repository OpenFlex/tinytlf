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
	public function home(target:IEventDispatcher):IObservable {
		return mac ? command(arrowright(target)) : keyequals(keydown(target), Keyboard.HOME);
	}	
}