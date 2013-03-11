package org.tinytlf.events.modifiers
{
	import flash.events.*;
	import flash.ui.*;
	
	import org.tinytlf.env.mac;
	
	import raix.reactive.*;
	
	/**
	 * @author ptaylor
	 */
	public function option(obs:IObservable):IObservable {
		return obs.filter(function(event:*):Boolean {
				return mac ? event.altKey : event.ctrlKey;
			});
	}
}