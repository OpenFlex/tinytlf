package org.tinytlf.handlers
{
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.partial;
	import asx.fn.sequence;

	/**
	 * @author ptaylor
	 */
	public const printComplete:Function = function(name:String):Function {
		return function(...args):void {
			trace('the', name, 'stream completed');
		}
	};
}