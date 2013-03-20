package org.tinytlf.handlers
{
	import asx.fn.I;

	/**
	 * @author ptaylor
	 */
	public function printNext(name:String, selector:Function = null):Function {
		selector ||= I;
		return function(next:*):void {
			trace('next on', name + ':', selector(next));
		};
	}
}