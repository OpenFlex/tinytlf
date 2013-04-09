package org.tinytlf.events.mouse
{
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function up(target:IEventDispatcher):IObservable {
		return Observable.fromEvent(target, MouseEvent.MOUSE_UP);
	}
}