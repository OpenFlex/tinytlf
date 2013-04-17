package org.tinytlf.types {
	import flash.utils.Dictionary;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	
	import raix.reactive.AbsObservable;
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObserver;
	import raix.reactive.ISubject;
	import raix.reactive.Notification;
	import raix.reactive.OnNext;
	import raix.reactive.TimeStamped;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.scheduling.Scheduler;
	
	/**
	 * DOMNode is a public API that allows manipulation of the underlying XML
	 * node, but broadcasts all updates so the system can react to them.
	 *
	 * The functional system could be written without this, but it's a
	 * convenient API to expose so we can live in an imperative world.
	 */
	public class DOMElement extends AbsObservable implements ISubject {
		
		public function DOMElement(region:Region, key:String, node:XML = null) {
			super();
			
			_region = region;
			_key = key;
			
			if(node != null) update(node);
		}
		
		public static const cache:Dictionary = new Dictionary(false);
		
		private var _key:String = '';
		
		public function get key():String {
			return _key;
		}
		
		private var _region:Region;
		
		public function get region():Region {
			return _region;
		}
		
		private var _node:XML = <_/>;
		
		public function get node():XML {
			return _node;
		}
		
		// Used for sorting intersections.
		public function get index():int {
			return node.childIndex();
		}
		
		/**
		 * A Subject that represents the current rendered status of this DOMNode
		 * after an update is made.
		 *
		 * <p>Every time the XML node is modified, a new Rendered Subject is
		 * created to track the progress of the rendering cycle. When a render
		 * occurs, the renderer should dispatch a new Rendered instance with
		 * the DOMElement and the newly rendered DisplayObject.</p>
		 */
		public const rendered:ISubject = new UnderlyingDOMElementSubject();
		
		public function update(node:XML):DOMElement {
			onNext(_node = node);
			return this;
		}
		
		private var _scheduler:IScheduler = Scheduler.synchronous;
		private var _bufferSize:uint = 1;
		private var _window:uint = 0;
		
		private var _values:Array = new Array(); // of Timestamp of Notification
		
		private var _liveObservers:Array = new Array();
		private var _observerValues:Array = new Array(); // of Array of Timestamp of Notification
		
		public override function subscribeWith(observer:IObserver):ICancelable {
			removeInvalidValues();
			
			var observerValues:Array = new Array(); // of Timestamp of Notification
			observerValues = observerValues.concat(_values);
			
			_observerValues.push(observerValues);
			
			var scheduledAction:ICancelable =
				Scheduler.scheduleRecursive(_scheduler, function(recurse:Function):void
				{
					if (observerValues.length > 0)
					{
						var not:Notification = observerValues.shift().value;
						not.acceptWith(observer);
						
						recurse();
					}
					else
					{
						_liveObservers.push(observer);
						
						var valuesIndex:int = _observerValues.indexOf(observerValues);
						
						if (valuesIndex != -1)
						{
							_observerValues.splice(valuesIndex, 1);
						}
					}
				
				}, 0);
			
			return Cancelable.create(function():void
			{
				scheduledAction.cancel();
				
				var observerIndex:int = _liveObservers.indexOf(observer);
				
				if (observerIndex != -1)
				{
					_liveObservers.splice(observerIndex, 1);
				}
				
				var valuesIndex:int = _observerValues.indexOf(observerValues);
				
				if (valuesIndex != -1)
				{
					_observerValues.splice(valuesIndex, 1);
				}
			});
		}
		
		private function removeInvalidValues():void {
			var removeForBufferSize:Boolean =
				(_bufferSize != 0 && _values.length > _bufferSize);
			
			var nowValue:Number = _scheduler.now.time;
			
			while (_values.length > 0 || removeForBufferSize) {
				var timestamp:TimeStamped = _values[0];
				
				var removeForWindow:Boolean =
					(_window != 0 && (nowValue - timestamp.timestamp) > _window);
				
				if (removeForBufferSize || removeForWindow) {
					_values.shift();
				} else {
					break;
				}
				
				removeForBufferSize = (_bufferSize != 0 && _values.length > _bufferSize);
			}
		}
		
		private function addValue(notification:Notification):void {
			var value:TimeStamped = new TimeStamped(notification, _scheduler.now.time);
			
			_values.push(value);
			
			for each (var observerValues:Array in _observerValues) {
				observerValues.push(value);
			}
			
			removeInvalidValues();
		}
		
		public function onNext(value:Object):void {
			addValue(new OnNext(value));
			
			for each (var liveObserver:IObserver in _liveObservers) {
				liveObserver.onNext(value);
			}
		}
		
		public function onCompleted():void {
			for each (var liveObserver:IObserver in _liveObservers) {
				liveObserver.onCompleted();
			}
			
			_liveObservers.length = 0;
		}
		
		public function onError(err:Error):void {
			for each (var liveObserver:IObserver in _liveObservers) {
				liveObserver.onError(err);
			}
			
			_liveObservers.length = 0;
		}
	}
}

import raix.reactive.AbsObservable;
import raix.reactive.Cancelable;
import raix.reactive.ICancelable;
import raix.reactive.IObserver;
import raix.reactive.ISubject;

internal class UnderlyingDOMElementSubject extends AbsObservable implements ISubject {
	private var _subscriptionCount:uint = 0;
	
	private var _observers:Array = new Array();
	
	public function UnderlyingDOMElementSubject() {
	}
	
	/**
	 * @inheritDoc
	 */
	public override function subscribeWith(observer:IObserver):ICancelable {
		_subscriptionCount++;
		
		_observers.push(observer);
		
		return Cancelable.create(function():void
		{
			var index:int = _observers.indexOf(observer);
			
			if (index != -1)
			{
				_observers.splice(index, 1);
			}
			
			_subscriptionCount--;
		});
	}
	
	/**
	 * @inheritDoc
	 */
	public function onNext(pl:Object):void {
		var observers:Array = _observers.slice();
		
		for each (var obs:IObserver in observers) {
			obs.onNext(pl);
		}
	}
	
	/**
	 * @inheritDoc
	 */
	public function onCompleted():void {
		var observers:Array = _observers.slice();
		
		for each (var obs:IObserver in observers) {
			obs.onCompleted();
		}
	}
	
	/**
	 * @inheritDoc
	 */
	public function onError(error:Error):void {
		var observers:Array = _observers.slice();
		
		for each (var obs:IObserver in observers) {
			obs.onError(error);
		}
	}
	
	/**
	 * Determines whether this subject has any subscriptions
	 */
	public function get hasSubscriptions():Boolean {
		return _subscriptionCount > 0;
	}
	
	/**
	 * Gets the number of subscriptions this subject has
	 */
	public function get subscriptionCount():int {
		return _subscriptionCount;
	}
}

