package org.tinytlf.fn
{
	/**
	 * @author ptaylor
	 */
	public function addInheritanceChain(node:XML):XML {
		node.@cssInheritanceChain = toInheritanceChain(node);
		return node;
	}	
}