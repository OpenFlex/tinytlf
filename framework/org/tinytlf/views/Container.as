package org.tinytlf.views
{
	import asx.array.allOf;
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.reduce;
	import asx.array.zip;
	import asx.fn.I;
	import asx.fn.aritize;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.sequence;
	import asx.object.isA;
	import asx.object.isAn;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.engine.TextLine;
	
	import mx.core.IUIComponent;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.renderedEvent;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Virtualizer;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.Observable;
	
	public class Container extends Box implements IDOMView
	{
		public function Container(region:Region)
		{
			super(region);
			
			subscriptions.add(region.viewports.subscribe(function(viewport:Rectangle):void {
				scrollRect = viewport;
			}));
		}
		
		// TODO: Abstract layouts
		override protected function draw():void {
			 
			// Size/layout any UIComponent children
			const components:Array = filter(children, isAn(IUIComponent));
			const sizes:Array = zip(
				pluck(components, 'getExplicitOrMeasuredWidth()'),
				pluck(components, 'getExplicitOrMeasuredHeight()')
			);
			
			const setSizeFns:Array = map(components, sequence(getProperty('setActualSize'), distribute));
			
			forEach(zip(setSizeFns, sizes), distribute(function(fn:Function, size:Array):void {
				fn(size);
			}));
			
			const domViews:Array = filter(children, isAn(IDOMView));
			const cache:Virtualizer = region.cache;
			
			// layout the y dimension
			forEach(domViews, function(view:IDOMView):void {
				view.y = cache.getStart(view.element);
			});
			
			super.draw();
		}
		
//		// TODO: layouts, measure content width, etc.
//		private var cWidth:Number = 1000;
//		public function get contentWidth():Number
//		{
//			return cWidth;
//		}
//		
//		// TODO: layouts, measure content height, etc.
//		private var cHeight:Number = 2000;
//		public function get contentHeight():Number
//		{
//			return cHeight;
//		}
//		
//		private var hScroll:Number = 0;
//		public function get horizontalScrollPosition():Number
//		{
//			return hScroll;
//		}
//		
//		public function set horizontalScrollPosition(value:Number):void
//		{
//			hScroll = value;
//		}
//		
//		private var vScroll:Number = 0;
//		public function get verticalScrollPosition():Number
//		{
//			return vScroll;
//		}
//		
//		public function set verticalScrollPosition(value:Number):void
//		{
//			vScroll = value;
//		}
//		
//		public function getHorizontalScrollPositionDelta(navigationUnit:uint):Number
//		{
//			return 10;
//		}
//		
//		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
//		{
//			return 10;
//		}
//		
//		public function get clipAndEnableScrolling():Boolean
//		{
//			return true;
//		}
//		
//		public function set clipAndEnableScrolling(value:Boolean):void
//		{
//		}
	}
}