package org.tinytlf.events
{
	import flash.events.*;

	/**
	 * @author ptaylor
	 */
	public function stop(event:Event):void {
		return event.stopPropagation();
	}
}