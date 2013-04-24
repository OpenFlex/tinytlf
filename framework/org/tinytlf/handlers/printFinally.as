package org.tinytlf.handlers
{
	/**
	 * @author ptaylor
	 */
	public function printFinally(name:String):Function {
		return function(...args):void {
			trace('the', name, 'completed or was unsubscribed from');
		}
	};
}