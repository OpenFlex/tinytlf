package org.tinytlf.lambdas
{
	/**
	 * @author ptaylor
	 */
	// parent#parentId .one .two child#id .one .two
	public function getNodeNameFromInheritance(key:String):String {
		return key.
			split(' ').
			filter(function(token:String, ...args):Boolean {
				return token.indexOf('.') == -1;
			}).
			pop().
			split('#')[0];
	}
}