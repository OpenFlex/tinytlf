package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function renderedEvent(...args):Event {
		return new Event(renderedEventType, false, false);
	}
}

