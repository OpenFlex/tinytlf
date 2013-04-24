package org.tinytlf.handlers
{
	import asx.fn._;
	import asx.fn.partial;

	/**
	 * @author ptaylor
	 */
	public const printError:Function = function(name:String, stack:Boolean = false):Function {
		return function(e:Error):void {
			trace('error in the', name, 'stream:', stack ? e.getStackTrace() : e.toString());
		}
	};
}