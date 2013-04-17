package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function updateEvent(...args):Event {
		return new Event(updateEventType, false, false);
	}
}