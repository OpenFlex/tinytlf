package org.tinytlf.views
{
	import flash.events.Event;
	
	import mx.core.UIComponent;
	
	import spark.core.IViewport;
	
	import asx.fn.I;
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.guard;
	import asx.fn.sequence;
	
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	
	import trxcllnt.ds.RTree;
	
	public class TextContainer extends UIComponent implements IViewport
	{
		public function TextContainer(region:Region)
		{
			super();
			
			this['region'] = region;
		}
		
		public const region:Region;
		
		override protected function createChildren():void {
			super.createChildren();
			
			const layout:IObservable = region.layoutCache;
			const subscriptions:CompositeCancelable = new CompositeCancelable();
			
			// When "render" is dispatched, invalidate the size and display list.
			subscriptions.add(Observable.fromEvent(this, 'render').
				subscribe(sequence(guard(invalidateSize), guard(invalidateDisplayList))));
			
			// Do measure after render.
			subscriptions.add(Observable.fromEvent(this, 'measure').
				combineLatest(layout, args).
				subscribe(function(event:Event, tree:RTree):void {
				}));
			
			// Do updateDisplayList after render.
			subscriptions.add(Observable.fromEvent(this, 'updateDisplayList').
				combineLatest(layout, args).
				subscribe(distribute(function(event:Event, tree:RTree):void {
					
			})));
			
			// Clean up subscriptions when we get taken off the screen.
			subscriptions.add(Observable.fromEvent(this, Event.REMOVED_FROM_STAGE).
				take(1).
				subscribe(I, subscriptions.cancel));
		}
		
		override protected function measure():void {
			super.measure();
			
			dispatchEvent(new Event('measure'));
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			dispatchEvent(new Event('updateDisplayList'));
		}
		
		private var cWidth:Number = 0;
		public function get contentWidth():Number
		{
			return cWidth;
		}
		
		private var cHeight:Number = 0;
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