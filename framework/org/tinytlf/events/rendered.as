package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function rendered():Event {
		return new Event('tinytlf_rendered');
	}
}

