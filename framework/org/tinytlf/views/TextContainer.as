package org.tinytlf.views
{
	import flash.display.Sprite;
	import flash.events.Event;
	
	import mx.core.IUIComponent;
	
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.zip;
	import asx.fn.I;
	import asx.fn.aritize;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.sequence;
	import asx.object.isA;
	
	import org.tinytlf.events.render;
	import org.tinytlf.events.rendered;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.ds.RTree;
	
	public class TextContainer extends Sprite
	{
		public function TextContainer(region:Region)
		{
			super();
			
			this['region'] = region;
			
			const subscriptions:CompositeCancelable = new CompositeCancelable();
			
			// When "render" is dispatched, invalidate the size and display list.
			subscriptions.add(Observable.fromEvent(this, render().type).
				subscribe(aritize(draw, 0)));
			
			// Clean up subscriptions when we get taken off the screen.
			subscriptions.add(
				Observable.fromEvent(this, Event.REMOVED_FROM_STAGE).
				take(1).
				subscribe(I, subscriptions.cancel)
			);
		}
		
		public const region:Region;
		
		public function get children():Array {
			const kids:Array = [];
			for(var i:int = 0, n:int = numChildren; i < n; ++i) kids.push(getChildAt(i))
			return kids;
		}
		
		protected function draw():void {
			x = region.x;
			y = region.y;
			
			const w:Number = region.width;
			const h:Number = region.height;
			
			// TODO: Abstract layouts.
			// 
			// Size/layout any UIComponent children
			const components:Array = filter(children, isA(IUIComponent));
			const sizes:Array = zip(
				pluck(components, 'getExplicitOrMeasuredWidth()'),
				pluck(components, 'getExplicitOrMeasuredHeight()')
			);
			
			const setSizeFns:Array = map(components, sequence(getProperty('setActualSize'), distribute));
			
			forEach(zip(setSizeFns, sizes), distribute(function(fn:Function, size:Array):void {
				fn(size);
			}));
			
			dispatchEvent(rendered());
		}
		
		// TODO: layouts, measure content width, etc.
		private var cWidth:Number = 1000;
		public function get contentWidth():Number
		{
			return cWidth;
		}
		
		// TODO: layouts, measure content height, etc.
		private var cHeight:Number = 2000;
		public function get contentHeight():Number
		{
			return cHeight;
		}
		
		private var hScroll:Number = 0;
		public function get horizontalScrollPosition():Number
		{
			return hScroll;
		}
		
		public function set horizontalScrollPosition(value:Number):void
		{
			hScroll = value;
		}
		
		private var vScroll:Number = 0;
		public function get verticalScrollPosition():Number
		{
			return vScroll;
		}
		
		public function set verticalScrollPosition(value:Number):void
		{
			vScroll = value;
		}
		
		public function getHorizontalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 10;
		}
		
		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 10;
		}
		
		public function get clipAndEnableScrolling():Boolean
		{
			return true;
		}
		
		public function set clipAndEnableScrolling(value:Boolean):void
		{
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