package org.tinytlf.views
{
	import asx.fn.I;
	import asx.fn.aritize;
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import org.tinytlf.events.renderEventType;
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.events.renderedEventType;
	import org.tinytlf.events.updateEventType;
	import org.tinytlf.events.updatedEvent;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.Observable;
	
	internal class Box extends Sprite implements IDOMView
	{
		public function Box(element:DOMElement)
		{
			super();
			
			_element = element;
			this['region'] = element.region;
			
			// layout when the "tinytlf_update" event is dispatched
			subscriptions.add(Observable.fromEvent(this, updateEventType).
				subscribe(aritize(layout, 0)));
			
			// render when the "tinytlf_render" event is dispatched
			subscriptions.add(Observable.fromEvent(this, renderEventType).
				subscribe(aritize(render, 0)));
			
			// Clean up subscriptions when we get taken off the screen.
			subscriptions.add(
				Observable.fromEvent(this, Event.REMOVED_FROM_STAGE, false, 0, true).
				take(1).
				subscribe(I, subscriptions.cancel)
			);
		}
		
		protected const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		public function get children():Array {
			const kids:Array = [];
			for(var i:int = 0, n:int = numChildren; i < n; ++i) kids.push(getChildAt(i))
			return kids;
		}
		
		private var _element:DOMElement;
		public const region:Region;
		
		public function get element():DOMElement {
			return _element;
		}
		
		/**
		 * The layout event is called each time the rendering algorithm adds or
		 * removes a child from this Sprite's DisplayList. It can be called
		 * multiple times in a rendering pass.
		 */
		protected function layout():void {
			x = region.x;
			y = region.y;
			
			dispatchEvent(updatedEvent());
		}
		
		/**
		 * Called at the end of a render cycle, after all children have been
		 * created, rendered, and added.
		 */
		protected function render():void {
			// Layout one last time before "rendered" is dispatched.
			layout();
			
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