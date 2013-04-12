package org.tinytlf.enumerables
{
	import org.tinytlf.procedures.applyNodeInheritance;
	
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;

	/**
	 * @author ptaylor
	 */
	public function childrenOfXML(node:XML, startIndex:int = 0):IEnumerable {
		const children:XMLList = node.children();
		
		return Enumerable.generate(
			startIndex,
			function(i:int):Boolean { return i < children.length();},
			function(i:int):int { return i + 1; },
			function(i:int):XML { return applyNodeInheritance(children[i]); }
		);
	}
}