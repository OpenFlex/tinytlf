package org.tinytlf.views
{
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.zip;
	import asx.fn.apply;
	import asx.fn.getProperty;
	import asx.fn.sequence;
	import asx.object.isAn;
	
	import flash.geom.Rectangle;
	
	import mx.core.IUIComponent;
	
	import org.tinytlf.types.DOMElement;
	
	import trxcllnt.vr.Virtualizer;
	
	public class Container extends Box implements IDOMView
	{
		public function Container(element:DOMElement)
		{
			super(element);
			
			subscriptions.add(region.viewports.subscribe(function(viewport:Rectangle):void {
				scrollRect = viewport;
			}));
		}
		
		public function get layoutChildren():Array {
			return filter(children, isAn(IDOMView));
		}
		
		// TODO: Abstract layouts
		override protected function layout():void {
			
			const cache:Virtualizer = region.cache;
			
			// layout the y dimension
			forEach(layoutChildren, function(view:IDOMView):void {
				view.y = cache.getStart(view.element);
			});
			
			super.layout();
		}
		
		override protected function render():void {
			// Size/layout any UIComponent children
			
			const components:Array = filter(children, isAn(IUIComponent));
			const sizes:Array = zip(
				pluck(components, 'getExplicitOrMeasuredWidth()'),
				pluck(components, 'getExplicitOrMeasuredHeight()')
			);
			
			const setSizeFns:Array = map(components, sequence(getProperty('setActualSize'), apply));
			
			forEach(zip(setSizeFns, sizes), apply(function(fn:Function, size:Array):void {
				fn(size);
			}));
			
			super.render();
		}
		
//		// TODO: layouts, measure content width, etc.
//		private var cWidth:Number = 1000;
//		public function get contentWidth():Number
//		{
//			return cWidth;
//		}
//		
//		public function setContentWidth(val:Number):Container {
//			cWidth = val;
//			return this;
//		}
//		
//		// TODO: layouts, measure content height, etc.
//		private var cHeight:Number = 2000;
//		public function get contentHeight():Number
//		{
//			return cHeight;
//		}
//		
//		public function setContentHeight(val:Number):Container {
//			cHeight = val;
//			return this;
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