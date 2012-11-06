package org.tinytlf.lambdas
{
	import org.tinytlf.classes.*;

	public function toStyleable(node:XML, root:CSS):Styleable {
		const styleable:Styleable = new Styleable();
		
		for each(var attr:XML in node.attributes()) {
			styleable[attr.localName()] = attr.toString();
		}
		
		styleable.mergeWith(root.lookup(styleable['cssInheritanceChain']));
		
		return styleable.hasOwnProperty('style') ?
			styleable.
				mergeWith(new CSS('inline_style{' + styleable['style'] + '}').
					lookup('inline_style')) :
			styleable;
	}
}