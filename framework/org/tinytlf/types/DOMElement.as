package org.tinytlf.types {
	import flash.utils.Dictionary;
	
	import asx.fn.sequence;
	
	import raix.reactive.AbsObservable;
	import raix.reactive.Cancelable;
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;
	import raix.reactive.subjects.IConnectableObservable;
	
	/**
	 * DOMNode is a public API that allows manipulation of the underlying XML
	 * node, but broadcasts all updates so the system can react to them.
	 *
	 * The functional system could be written without this, but it's a
	 * convenient API to expose so we can live in an imperative world.
	 */
	public class DOMElement extends AbsObservable {
		private var _subject:ISubject;
		private var _subscription:CompositeCancelable;
		
		public function DOMElement(key:String) {
			super();
			
			_key = key;
		}
		
		public static const cache:Dictionary = new Dictionary(false);
		
		private var _key:String = '';
		
		public function get key():String {
			return _key;
		}
		
		private var _node:XML = <_/>;
		
		public function get node():XML {
			return _node;
		}
		
		// Used for sorting intersections.
		public function get index():int {
			return node.childIndex();
		}
		
		public function set source(value:IObservable):void {
			if (_subscription)
				_subscription.cancel();
			
			const connectable:IConnectableObservable = value.multicast(_subject = new Subject());
			
			_subscription = new CompositeCancelable();
			_subscription.add(_subject.subscribe(updateNode));
			_subscription.add(Cancelable.create(function():void {
				_subscription = null;
			}));
			_subscription.add(connectable.connect());
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
		private var _rendered:ISubject = new UnderlyingDOMElementSubject();
		
		public function get rendered():ISubject {
			return _rendered;
		}
		
		private function updateNode(node:XML):void {
			_node = node;
		}
		
		public function update(node:XML, suppressUpdate:Boolean = false):DOMElement {
			updateNode(node);
			
			// Only dispatch the update the node is on the screen.
			if (suppressUpdate || !_subscription)
				return this;
			
			_subject.onNext(_node);
			
			return this;
		}
		
		override public function subscribeWith(observer:IObserver):ICancelable {
			return _subject.subscribeWith(observer);
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
