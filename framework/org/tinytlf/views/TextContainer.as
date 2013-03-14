package org.tinytlf.views
{
	import flash.events.Event;
	
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	
	import spark.core.IViewport;
	
	import asx.array.filter;
	import asx.array.forEach;
	import asx.array.map;
	import asx.array.pluck;
	import asx.array.zip;
	import asx.fn.I;
	import asx.fn.aritize;
	import asx.fn.callFunction;
	import asx.fn.callProperty;
	import asx.fn.distribute;
	import asx.fn.getProperty;
	import asx.fn.guard;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.isA;
	import asx.object.newInstance_;
	
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Plan;
	
	public class TextContainer extends UIComponent implements IViewport
	{
		public function TextContainer(region:Region)
		{
			super();
			
			this['region'] = region;
			
			const cache:IObservable = region.cache;
			const subscriptions:CompositeCancelable = new CompositeCancelable();
			
			// When "render" is dispatched, invalidate the size and display list.
			subscriptions.add(
				Observable.fromEvent(this, 'render').
				subscribe(sequence(aritize(invalidateSize, 0), aritize(invalidateDisplayList, 0)))
			);
			
			const measured:IObservable = Observable.fromEvent(this, 'measure');
			const updated:IObservable = Observable.fromEvent(this, 'updateDisplayList');
			
			const rendered:Plan = measured.and(updated).then(aritize(partial(newInstance_, Event, 'rendered'), 0));
			
			// Dispatch the "rendered" event after "measure" and
			// "updateDisplayList" have both dispatched.
			subscriptions.add(Observable.when([rendered]).subscribe(dispatchEvent));
			
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
		
		override protected function measure():void {
			super.measure();
			
			dispatchEvent(new Event('measure'));
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			region.width = w;
			region.height = h;
			
			// TODO: Abstract layouts
			const components:Array = filter(children, isA(IUIComponent));
			const sizes:Array = zip(
				pluck(components, 'getExplicitOrMeasuredWidth()'),
				pluck(components, 'getExplicitOrMeasuredHeight()')
			);
			
			const setSizeFns:Array = map(components, sequence(getProperty('setActualSize'), distribute));
			
			forEach(zip(setSizeFns, sizes), distribute(function(fn:Function, size:Array):void {
				fn(size);
			}));
			
			dispatchEvent(new Event('updateDisplayList'));
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
	}
}