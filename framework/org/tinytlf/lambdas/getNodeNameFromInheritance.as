package org.tinytlf.lambdas
{
	import asx.array.filter;

	/**
	 * @author ptaylor
	 */
	// parent#parentId .one .two child#id:0 .one .two
	public function getNodeNameFromInheritance(key:String):String {
		return key.split(' ').
			filter(function(token:String, ...args):Boolean {
				return token.indexOf('.') == -1;
			}).
			pop().
			split(':').shift().
			split('#').shift();
	}
}