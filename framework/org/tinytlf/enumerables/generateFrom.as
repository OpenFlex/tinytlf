package org.tinytlf.enumerables
{
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;

	/**
	 * @author ptaylor
	 */
	public function generateFrom(list:Array, start:int = 0):IEnumerable {
		return Enumerable.generate(
			start,
			function(i:int):Boolean { return i < list.length;},
			function(i:int):int { return i + 1; },
			function(i:int):* { return list[i]; }
		);
	}
}