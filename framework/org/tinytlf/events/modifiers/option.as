package org.tinytlf.events.modifiers
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.*;
	import org.tinytlf.events.keyboard.*;
	import org.tinytlf.lambdas.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function option(obs:IObservable):IObservable {
		return obs.takeWhile(function(event:*):Boolean {
				return mac ? event.altKey : event.ctrlKey;
			}).
			takeUntil(keyequals(keyup(TextEngine.stage), Keyboard.ALTERNATE)).
			repeat();
	}
}