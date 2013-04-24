package org.tinytlf.fn
{
	/**
	 * @author ptaylor
	 */
	public function wrapTextNodes(node:XML, recurse:Boolean = false):XML {
		if(node.localName() == 'text') return node;
		
		for each(var child:XML in node.*) {
			if(child.localName() == 'text') continue;
			else if(child.nodeKind() == 'text') node.replace(child.childIndex(), <text>{child}</text>);
			else if(recurse) wrapTextNodes(child);
		}
		
		return node;
	}
}