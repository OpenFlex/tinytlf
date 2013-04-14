package org.tinytlf.views
{
	import asx.fn.I;
	import asx.fn.aritize;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import org.tinytlf.events.renderEventType;
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.events.renderedEventType;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.Observable;
	
	internal class Box extends Sprite implements IDOMView
	{
		public function Box(region:Region)
		{
			super();
			
			this['region'] = region;
			
			// When "render" is dispatched, invalidate the size and display list.
			subscriptions.add(Observable.fromEvent(this, renderEventType).
				subscribe(aritize(draw, 0)));
			
			// Clean up subscriptions when we get taken off the screen.
			subscriptions.add(
				Observable.fromEvent(this, Event.REMOVED_FROM_STAGE, false, 0, true).
				take(1).
				subscribe(I, subscriptions.cancel)
			);
			
			visible = false;
			subscriptions.add(Observable.fromEvent(this, renderedEventType).
				first().subscribe(function(...args):void {
					visible = true;
				}));
		}
		
		protected const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		public function get children():Array {
			const kids:Array = [];
			for(var i:int = 0, n:int = numChildren; i < n; ++i) kids.push(getChildAt(i))
			return kids;
		}
		
		public const region:Region;
		
		public function get element():DOMElement {
			return region.element;
		}
		
		protected function draw():void {
			x = region.x;
			y = region.y;
			
			dispatchEvent(renderedEvent());
		}
		
		override public function get x():Number {
			return region.x;
		}
		
		override public function set x(value:Number):void {
			super.x = region.x = value;
		}
		
		override public function get y():Number {
			return region.y;
		}
		
		override public function set y(value:Number):void {
			super.y = region.y = value;
		}
		
		override public function get width():Number {
			return region.width;
		}
		
		override public function set width(value:Number):void {
			region.width = value;
		}
		
		override public function get height():Number {
			return region.height;
		}
		
		override public function set height(value:Number):void {
			region.height = value;
		}
	}
}