package org.tinytlf.fn
{
	/**
	 * @author ptaylor
	 */
	public function identify(value:*):Function {
		return function(...args):* { return value; };
	}
}