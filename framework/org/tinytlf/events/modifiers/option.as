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
		return obs.filter(function(event:*):Boolean {
				return TextEngine.mac ? event.altKey : event.ctrlKey;
			});
	}
}