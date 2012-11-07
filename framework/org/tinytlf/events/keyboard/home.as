package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.*;
	import org.tinytlf.events.modifiers.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function home(target:IEventDispatcher):IObservable {
		return TextEngine.mac ? command(arrowright(target)) : keyequals(keydown(target), Keyboard.HOME);
	}	
}