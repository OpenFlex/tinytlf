package org.tinytlf.handlers
{
	import asx.fn._;
	import asx.fn.partial;

	/**
	 * @author ptaylor
	 */
	public const printError:Function = function(name:String):Function {
		return function(...args):void {
			trace('error in the', _, ' stream:', name);
		}
	};
}