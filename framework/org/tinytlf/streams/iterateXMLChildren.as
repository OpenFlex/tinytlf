package org.tinytlf.streams
{
	import raix.reactive.*;

	/**
	 * @author ptaylor
	 */
	public function iterateXMLChildren(node:XML):IObservable {
		const children:XMLList = node.children();
		
		return Observable.generate(
			0,
			function(i:int):Boolean { return i < children.length();},
			function(i:int):int { return i + 1; },
			function(i:int):XML {
				return children[i];
			}
		);
	}
}