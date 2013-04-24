package org.tinytlf.views
{
	import asx.fn.I;
	import asx.fn.aritize;
	import asx.fn.noop;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import org.tinytlf.events.renderEventType;
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.events.updateEventType;
	import org.tinytlf.events.updatedEvent;
	import org.tinytlf.observables.Values;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.Observable;
	
	internal class Box extends Sprite implements TTLFView
	{
		public function Box(element:Values)
		{
			super();
			
			_element = element;
			
			// layout when the "tinytlf_update" event is dispatched
			Observable.fromEvent(this, updateEventType).subscribe(aritize(layout, 0));
			
			// render when the "tinytlf_render" event is dispatched
			Observable.fromEvent(this, renderEventType).subscribe(aritize(render, 0));
			
			element.subscribe(noop, subscriptions.cancel);
		}
		
		protected const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		public function get children():Array {
			const kids:Array = [];
			for(var i:int = 0, n:int = numChildren; i < n; ++i) kids.push(getChildAt(i))
			return kids;
		}
		
		private var _element:Values;
		
		public function get element():Values {
			return _element;
		}
		
		/**
		 * The layout event is called each time the rendering algorithm adds or
		 * removes a child from this Sprite's DisplayList. It can be called
		 * multiple times in a rendering pass.
		 */
		protected function layout():void {
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
		
		public function get viewport():Rectangle {
			return element.viewport;
		}
		
		override public function get x():Number {
			return element.x;
		}
		
		override public function set x(value:Number):void {
			super.x = element.x = value;
		}
		
		override public function get y():Number {
			return element.y;
		}
		
		override public function set y(value:Number):void {
			super.y = element.y = value;
		}
		
		override public function get width():Number {
			return element.width;
		}
		
		override public function set width(value:Number):void {
			element.width = value;
		}
		
		override public function get height():Number {
			return element.height;
		}
		
		override public function set height(value:Number):void {
			element.height = value;
		}
	}
}