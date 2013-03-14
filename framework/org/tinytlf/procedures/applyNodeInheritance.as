package org.tinytlf.procedures
{
	import org.tinytlf.lambdas.toInheritanceChain;

	/**
	 * @author ptaylor
	 */
	public function applyNodeInheritance(node:XML):XML {
		node.@cssInheritanceChain = toInheritanceChain(node);
		return node;
	}	
}