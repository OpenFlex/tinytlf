package org.tinytlf.handlers
{
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	import raix.reactive.ICancelable;

	/**
	 * @author ptaylor
	 */
	public function executeThenCancel(cancelable:ICancelable):Function {
		return partial(sequence, _, aritize(cancelable.cancel, 0));
	}
}