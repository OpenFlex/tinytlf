package org.tinytlf.handlers
{
	/**
	 * @author ptaylor
	 */
	public function printError(name:String, stack:Boolean = false):Function {
		return function(e:Error):void {
			trace('error in the', name, 'stream:', stack ? e.getStackTrace() : e.toString());
		}
	};
}