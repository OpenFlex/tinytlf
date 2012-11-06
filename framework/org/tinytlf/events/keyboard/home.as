package org.tinytlf.events.keyboard
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.events.modifiers.*;
	import org.tinytlf.lambdas.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function home(target:IEventDispatcher):IObservable {
		return mac ? command(right(target)) : keyequals(keydown(target), Keyboard.HOME);
	}	
}