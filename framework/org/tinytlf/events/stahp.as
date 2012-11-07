package org.tinytlf.events
{
	import flash.events.*;
	
	/**
	 * @author ptaylor
	 */
	// STAHP
	public function stahp(event:Event):void {
		event.stopImmediatePropagation()
		event.stopPropagation();
	}
}