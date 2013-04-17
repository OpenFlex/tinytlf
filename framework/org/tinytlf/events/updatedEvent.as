package org.tinytlf.events
{
	import flash.events.Event;
	
	/**
	 * @author ptaylor
	 */
	public function updatedEvent(...args):Event {
		return new Event(updatedEventType, false, false);
	}
}