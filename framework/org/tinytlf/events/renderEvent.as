package org.tinytlf.events
{
	import flash.events.Event;

	/**
	 * @author ptaylor
	 */
	public function renderEvent(...args):Event {
		return new Event('tinytlf_render', false, false);
	}
}