package org.tinytlf.fn
{
	/**
	 * Get the fully traversed inheritance chain of an XML node,
	 * including parent nodes, class list, and IDs.
	 */
	public function toInheritanceChain(node:XML):String
	{
		const index:int = node.childIndex();
		const name:String = node.localName() || 'text';
		const parent:XML = node.parent();
		
		const classes:String = String(node.@['class'] || '').split(' ').join(' .');
		const id:String = node.@id.length > 0 ? '#' + node.@id : '';
		const existingChain:String = parent ? parent.@cssInheritanceChain : '';
		
		return existingChain + (existingChain ? ' ' : '') + name + id + (index == -1 ? '' : ':' + index) + (classes ? ' .' : '') + classes;
	}
}