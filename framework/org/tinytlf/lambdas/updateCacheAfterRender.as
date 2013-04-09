package org.tinytlf.lambdas
{
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Rendered;
	import org.tinytlf.types.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function updateCacheAfterRender(cache:Virtualizer):Function {
		return function(rendered:Rendered):void {
			
			const size:Number = rendered.display.height;
			const element:DOMElement = rendered.element;
			const childIndex:int = element.node.childIndex();
			const index:int = cache.getIndex(rendered.element);
			
			if(index == -1) {
				cache.add(element, size);
			}
			else if(index != childIndex) {
				cache.removeAt(index);
				cache.addAt(element, childIndex, size);
			} else {
				cache.setSizeAt(index, size);
			}
		};
	}
}