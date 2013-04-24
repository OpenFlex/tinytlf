package org.tinytlf.handlers
{
	/**
	 * @author ptaylor
	 */
	public function printComplete(name:String):Function {
		return function(...args):void {
			trace('the', name, 'stream completed');
		}
	};
}