package org.tinytlf.events
{
	import flash.events.*;

	/**
	 * @author ptaylor
	 */
	public function prevent(event:Event):void {
		return event.preventDefault();
	}	
}