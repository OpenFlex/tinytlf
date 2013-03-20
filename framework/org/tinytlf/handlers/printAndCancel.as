package org.tinytlf.handlers
{
	import raix.reactive.ICancelable;

	/**
	 * @author ptaylor
	 */
	public function printAndCancel(cancelable:ICancelable, order:Function, streamName:String):Function {
		return executeThenCancel(cancelable)(order(streamName));
	}
}