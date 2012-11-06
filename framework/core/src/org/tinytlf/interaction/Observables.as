package org.tinytlf.interaction
{
	import flash.events.*;
	import flash.utils.*;
	
	import raix.reactive.*;
	
	public class Observables
	{
		protected const globalCanceleables:Dictionary = new Dictionary(false);
		
		public function register(target:IEventDispatcher):IEventDispatcher
		{
			globalCanceleables[target] ||= [];
			const a:Array = globalCanceleables[target];
			
			if(a.length <= 0)
			{
				a.push(mouseUp(target).subscribeWith(upObs));
				a.push(mouseOver(target).subscribeWith(overObs));
				a.push(mouseOut(target).subscribeWith(outObs));
				a.push(mouseRollOver(target).subscribeWith(rollOverObs));
				a.push(mouseRollOut(target).subscribeWith(rollOutObs));
				a.push(mouseMove(target).subscribeWith(moveObs));
				
				a.push(mouseDown(target).subscribeWith(downObs));
				a.push(mouseDoubleDown(target).subscribeWith(doubleDownObs));
				a.push(mouseTripleDown(target).subscribeWith(tripleDownObs));
				
				a.push(mouseClick(target).subscribeWith(clickObs));
				a.push(mouseDoubleClick(target).subscribeWith(doubleClickObs));
				
				a.push(mouseDrag(target).subscribeWith(dragObs));
				a.push(mouseDoubleDrag(target).subscribeWith(doubleDragObs));
				a.push(mouseTripleDrag(target).subscribeWith(tripleDragObs));
				
				a.push(mouseWheel(target).subscribeWith(wheelObs));
			}
			
			return target;
		}
		
		public function unregister(target:IEventDispatcher):IEventDispatcher
		{
			const a:Array = globalCanceleables[target] || [];
			a.forEach(function(subscription:ICancelable, ... args):void {
				subscription.cancel();
			});
			a.length = 0;
			
			delete globalCanceleables[target];
			
			return target;
		}
		
		protected const upObs:ISubject = new Subject();
		protected const overObs:ISubject = new Subject();
		protected const outObs:ISubject = new Subject();
		protected const rollOverObs:ISubject = new Subject();
		protected const rollOutObs:ISubject = new Subject();
		protected const moveObs:ISubject = new Subject();
		protected const clickObs:ISubject = new Subject();
		protected const downObs:ISubject = new Subject();
		protected const doubleClickObs:ISubject = new Subject();
		protected const doubleDownObs:ISubject = new Subject();
		protected const tripleDownObs:ISubject = new Subject();
		protected const dragObs:ISubject = new Subject();
		protected const doubleDragObs:ISubject = new Subject();
		protected const tripleDragObs:ISubject = new Subject();
		protected const wheelObs:ISubject = new Subject();
		
		public function get up():IObservable
		{
			return upObs;
		}
		
		public function get over():IObservable
		{
			return overObs;
		}
		
		public function get out():IObservable
		{
			return outObs;
		}
		
		public function get rollOver():IObservable
		{
			return rollOverObs;
		}
		
		public function get rollOut():IObservable
		{
			return rollOutObs;
		}
		
		public function get move():IObservable
		{
			return moveObs;
		}
		
		public function get down():IObservable
		{
			return downObs;
		}
		
		public function get doubleDown():IObservable
		{
			return doubleDownObs;
		}
		
		public function get tripleDown():IObservable
		{
			return tripleDownObs;
		}
		
		public function get click():IObservable
		{
			return clickObs;
		}
		
		public function get doubleClick():IObservable
		{
			return doubleClickObs;
		}
		
		public function get drag():IObservable
		{
			return dragObs;
		}
		
		public function get doubleDrag():IObservable
		{
			return doubleDragObs;
		}
		
		public function get tripleDrag():IObservable
		{
			return tripleDragObs;
		}
		
		public function get wheel():IObservable
		{
			return wheelObs;
		}
		
		protected const cachedObservables:Dictionary = new Dictionary(false);
		public function mouseUp(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.MOUSE_UP, false, 0, true),
							'up');
		}
		
		public function mouseOver(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.MOUSE_OVER, false, 0, true),
							'over');
		}
		
		public function mouseOut(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.MOUSE_OUT, false, 0, true),
							'out');
		}
		
		public function mouseRollOver(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.ROLL_OVER, false, 0, true),
							'rollOver');
		}
		
		public function mouseRollOut(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.ROLL_OUT, false, 0, true),
							'rollOut');
		}
		
		public function mouseMove(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.MOUSE_MOVE, false, 0, true),
							'move');
		}
		
		protected function downGenerator(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
				Observable.fromEvent(target, MouseEvent.MOUSE_DOWN).
					scan(function(state:Object, evt:MouseEvent):Object {
						return {val: state.val + 1, event: evt};
					}, {val: 0, event: null}, true).
					takeUntil(Observable.timer(800, 0)).
					repeat(),
				'downGenerator');
		}
		
		public function mouseDown(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							downGenerator(target).filter(function(tuple:Object):Boolean {
								return tuple.val == 1;
							}).
							map(function(tuple:Object):MouseEvent {
								return tuple.event;
							}),
							'down');
		}
		
		public function mouseDoubleDown(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							downGenerator(target).filter(function(tuple:Object):Boolean {
								return tuple.val == 2;
							}).
							map(function(tuple:Object):MouseEvent {
								return tuple.event;
							}),
							'doubleDown');
		}
		
		public function mouseTripleDown(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							downGenerator(target).filter(function(tuple:Object):Boolean {
								return tuple.val == 3;
							}).
							map(function(tuple:Object):MouseEvent {
								return tuple.event;
							}),
							'tripleDown');
		}
		
		public function mouseClick(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.CLICK, false, 0, true),
							'click');
		}
		
		public function mouseDoubleClick(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							mouseClick(target).
								timeInterval().
								filter(function(ti:TimeInterval):Boolean {
									return ti.interval > 0 && ti.interval < 400;
								}).
								removeTimeInterval(),
							'doubleClick');
		}
		
		public function mouseDrag(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							mouseDown(target).mapMany(function(me:MouseEvent):IObservable {
								return move.takeUntil(up);
							}),
							'drag');
		}
		
		public function mouseDoubleDrag(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							mouseDoubleDown(target).mapMany(function(me:MouseEvent):IObservable {
								return move.takeUntil(up);
							}),
							'doubleDrag');
		}
		
		public function mouseTripleDrag(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							mouseTripleDown(target).mapMany(function(me:MouseEvent):IObservable {
								return move.takeUntil(up);
							}),
							'tripleDrag');
		}
		
		public function mouseWheel(target:IEventDispatcher):IObservable
		{
			return cacheObs(target,
							Observable.fromEvent(target, MouseEvent.MOUSE_WHEEL),
							'wheel');
		}
		
		protected function cacheObs(target:IEventDispatcher, obs:IObservable, name:String):IObservable
		{
			cachedObservables[target] ||= {};
			return cachedObservables[target][name] ||= obs;
		}
	}
}
