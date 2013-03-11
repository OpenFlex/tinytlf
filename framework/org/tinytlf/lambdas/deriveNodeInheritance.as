package org.tinytlf.lambdas
{
	/**
	 * Get the fully traversed inheritance chain of an XML node,
	 * including parent nodes, class list, and IDs.
	 */
	public function deriveNodeInheritance(node:XML):String
	{
		const index:int = node.childIndex();
		const name:String = node.localName();
		const parent:XML = node.parent();
		
		const classes:String = String(node.@['class'] || '').split(' ').join(' .');
		const id:String = node.@id ? '#' + node.@id : '';
		const existingChain:String = parent ? parent.@cssInheritanceChain : '';
		
		return existingChain + (existingChain ? ' ' : '') + name + id + (index == -1 ? '' : ':' + index) + (classes ? ' .' : '') + classes;
	}
}