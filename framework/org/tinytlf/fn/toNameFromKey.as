package org.tinytlf.fn
{
	import asx.array.filter;

	/**
	 * @author ptaylor
	 */
	// parent#parentId .one .two child#id:0 .one .two
	public function toNameFromKey(key:String):String {
		return key.split(' ').
			filter(function(token:String, ...args):Boolean {
				return token.indexOf('.') == -1;
			}).
			pop().
			split(':').shift().
			split('#').shift();
	}
}