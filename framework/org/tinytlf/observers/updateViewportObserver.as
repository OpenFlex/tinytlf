package org.tinytlf.observers
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObserver;
	import raix.reactive.Observer;

	/**
	 * @author ptaylor
	 */
	public function updateViewportObserver(child:Values):IObserver {
		return Observer.create(function(parent:Rectangle):void {
			
			const viewport:Rectangle = child.viewport.clone();
			
			const pVSP:Number = parent.y; // parent vertical scroll position
			const cVSP:Number = viewport.y; // child vertical scroll position
			const y:Number = child.y; // Child y layout coord
			
			if(y == undefined) return;
			
			viewport.y = Math.max(0, pVSP - y);
			
			// Only set the viewport if the Y value actually changed :>
			if(viewport.y == cVSP) return;
			
			child.viewport = viewport;
		});
	}
}