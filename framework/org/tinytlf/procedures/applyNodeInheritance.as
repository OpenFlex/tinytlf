package org.tinytlf.procedures
{
	import org.tinytlf.lambdas.deriveNodeInheritance;

	/**
	 * @author ptaylor
	 */
	public function applyNodeInheritance(node:XML):XML {
		node.@cssInheritanceChain = deriveNodeInheritance(node);
		return node;
	}	
}