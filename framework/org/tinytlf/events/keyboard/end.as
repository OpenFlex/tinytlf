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
	public function end(target:IEventDispatcher):IObservable {
		return TextEngine.mac ? command(arrowleft(target)) : keyequals(keydown(target), Keyboard.END);
	}	
}