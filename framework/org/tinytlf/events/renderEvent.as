package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function renderEvent(...args):Event {
		return new Event(renderEventType, false, false);
	}
}