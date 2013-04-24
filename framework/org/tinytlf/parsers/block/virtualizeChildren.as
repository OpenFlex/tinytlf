package org.tinytlf.parsers.block
{
	import asx.fn.I;
	import asx.fn._;
	import asx.fn.apply;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	internal function virtualizeChildren(visibleSelector:Function, render:Function, monitor:Function):Function {
		
		const selectVisible:Function = sequence(
			visibleSelector,
			callProperty('map', distribute(I, render)),
			callProperty('map', apply(monitor)),
			callProperty('map', callProperty('take', 1)),
			callProperty('concatMany')
		);
		
		return partial(virtualize, _, _, selectVisible);
	}
}
