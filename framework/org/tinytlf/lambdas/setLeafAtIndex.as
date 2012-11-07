package org.tinytlf.lambdas
{
	/**
	 * @author ptaylor
	 */
	public function setLeafAtIndex(node:XML, leaf:*, index:int):XML {
		
		const numChildren:int = node.*.length();
		const children:XML = <_/>
		var offset:int = 0;
		
		for(var i:int = -1; ++i < numChildren;) {
			const child:XML = node.children()[i];
			const len:int = (child.hasComplexContent() ? child.text() : child).toString().length;
			
			if(index < offset + len) {
				if(child.hasSimpleContent()) {
					children.appendChild(leaf);
				} else {
					children.appendChild(setLeafAtIndex(node, leaf, index - offset));
				}
			} else {
				children.appendChild(child);
			}
			
			offset += len;
		}
		
		return node.setChildren(children.children());
	}
}