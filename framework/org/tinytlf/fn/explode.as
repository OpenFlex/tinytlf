package org.tinytlf.fn
{
	/**
	 * @author ptaylor
	 */
	public function explode(fn:Function) {
		return function(args:Array):* {
			return fn.apply(null, args.slice(0, fn.length));
		}
	}
}