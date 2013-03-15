package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function render():Event {
		return new Event('tinytlf_render');
	}
}