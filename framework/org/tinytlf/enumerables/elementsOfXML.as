package org.tinytlf.enumerables
{
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;
	import raix.interactive.toEnumerable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function elementsOfXML(node:XML, startIndex:int = 0):IEnumerable {
		const children:XMLList = node.elements();
		
		return Enumerable.generate(
			startIndex,
			function(i:int):Boolean { return i < children.length();},
			function(i:int):int { return i + 1; },
			function(i:int):XML { return children[i]; }
		);
	}
}