package org.tinytlf.observables {
	import raix.reactive.IObserver;
	import raix.reactive.IObservable;
	import raix.reactive.AbsObservable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.ICancelable;
	
	public class GroupedObservable extends AbsObservable implements IGroupedObservable {
		private var _underlyingObservable:IObservable;
		private var _key:Object;
		
		public function GroupedObservable(key:Object, underlyingObservable:IObservable) {
			_underlyingObservable = underlyingObservable;
			_key = key;
		}
		
		public function get key():Object {
			return _key;
		}
		
		public override function subscribeWith(observer:IObserver):ICancelable {
			return _underlyingObservable.subscribeWith(observer);
		}
	}
}