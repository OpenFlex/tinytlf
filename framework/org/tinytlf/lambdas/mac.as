package org.tinytlf.lambdas
{
	import flash.system.Capabilities;

	/**
	 * @author ptaylor
	 */
	public const mac:Boolean = (/mac/i).test(Capabilities.os);
}