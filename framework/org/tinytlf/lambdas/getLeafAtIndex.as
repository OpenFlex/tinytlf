package org.tinytlf.lambdas
{
	/**
	 * @author ptaylor
	 */
	public function getLeafAtIndex(node:XML, index:int):Array/*<XML, int>*/ {
		const numChildren:int = node.*.length();
		var offset:int = 0;
		
		for(var i:int = -1; ++i < numChildren;) {
			const child:XML = node.children()[i];
			const len:int = (child.hasComplexContent() ? child.text() : child).toString().length;
			
			if(index < offset + len)
				return getLeafAtIndex(child, index - offset);
			
			offset += len;
		}
		
		return [node, index];
	}
}