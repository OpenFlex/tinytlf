package org.tinytlf.events.mouse
{
	import flash.events.*;
	
	import raix.reactive.*;

	/**
	 * @author ptaylor
	 */
	public function down(target:IEventDispatcher):IObservable {
		return Observable.fromEvent(target, MouseEvent.MOUSE_DOWN);
	}
}