package org.tinytlf.lambdas
{
	/**
	 * @author ptaylor
	 */
	public function applyInheritanceChain(node:XML):XML {
		node.@cssInheritanceChain = getInheritanceChain(node);
		return node;
	}	
}