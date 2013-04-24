package org.tinytlf.observers
{
	import asx.fn.apply;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.partial;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObserver;
	import raix.reactive.Observer;

	/**
	 * @author ptaylor
	 */
	public function displayListObserver(container:DisplayObjectContainer):IObserver {
		var removeChild:Function = noop;
		
		const complete:Function = function():void {
			removeChild();
		};
		
		const next:Function = apply(function(element:Values, child:DisplayObject):void {
			
			if(child == null) return;
			
			removeChild = ifElse(
				partial(container.contains, child),
				partial(container.removeChild, child),
				noop
			);
			
			const nodeIndex:int = element.index;
			const childIndex:int = Math.max(Math.min(nodeIndex, container.numChildren), 0);
			
			if(container.contains(child) && container.getChildIndex(child) == childIndex) {
				return;
			}
			
			container.addChildAt(child, childIndex);
		});
		
		return Observer.create(next, complete);
	}
}