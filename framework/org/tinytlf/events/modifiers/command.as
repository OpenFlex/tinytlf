package org.tinytlf.events.modifiers
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.values.*;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function command(obs:IObservable):IObservable {
		return obs.filter(function(event:*):Boolean {
			return event.ctrlKey;
		});
	}
}