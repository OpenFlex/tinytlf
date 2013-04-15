package org.tinytlf.types
{
	import asx.fn.args;
	import asx.fn.distribute;
	
	import flash.geom.Rectangle;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.vr.Virtualizer;
	
	public class Region extends Styleable
	{
		public function Region(pvScroll:IObservable, phScroll:IObservable) {
			super();
			
			// For virtualization, listen to the parent's vertical and horizontal
			// scroll values and adjust ours when their values scroll beyond ours.
			// This ensures we can virtualize our children relative to our (0, 0)
			// coordinate space.
			
			const parentMinusChild:Function = function(parent:Number, child:Number):Number {
				return parent - child;
			};
			const parentPlusChild:Function = function(parent:Number, child:Number):Number {
				return parent + child;
			};
			const greaterThan0:Function = function(val:Number):Boolean {
				return val >= 0;
			};
			
			pvScroll.distinctUntilChanged().
				combineLatest(ySubj.distinctUntilChanged(), parentMinusChild).
				filter(greaterThan0).
				combineLatest(vScroll.distinctUntilChanged(), parentPlusChild).
				map(function(y:Number):Rectangle {
					const r:Rectangle = _viewport.value.clone();
					r.offset(0, y - r.y);
					return r;
				}).
				multicast(_viewport).
				connect();
			
			phScroll.distinctUntilChanged().
				combineLatest(xSubj.distinctUntilChanged(), parentMinusChild).
				filter(greaterThan0).
				combineLatest(hScroll.distinctUntilChanged(), parentPlusChild).
				map(function(x:Number):Rectangle {
					const r:Rectangle = _viewport.value.clone();
					r.offset(x - r.x, 0);
					return r;
				}).
				multicast(_viewport).
				connect();
		}
		
		public const xSubj:BehaviorSubject = new BehaviorSubject(0);
		public function get x():Number {
			return xSubj.value;
		}
		
		public function set x(value:Number):void {
			xSubj.onNext(value);
		}
		
		public const ySubj:BehaviorSubject = new BehaviorSubject(0);
		public function get y():Number {
			return ySubj.value;
		}
		
		public function set y(value:Number):void {
			ySubj.onNext(value);
		}
		
		public const widthSubj:BehaviorSubject = new BehaviorSubject(0);
		public function get width():Number {
			return widthSubj.value;
		}
		
		public function set width(w:Number):void {
			widthSubj.onNext(w);
		}
		
		public const heightSubj:BehaviorSubject = new BehaviorSubject(0);
		public function get height():Number {
			return heightSubj.value;
		}
		
		public function set height(h:Number):void {
			heightSubj.onNext(h);
		}
		
		public const elementSubj:BehaviorSubject = new BehaviorSubject(0);
		public function get element():DOMElement {
			return elementSubj.value;
		}
		
		public function set element(e:DOMElement):void {
			elementSubj.onNext(e);
		}
		
		public const vScroll:BehaviorSubject = new BehaviorSubject(0);
		public function get verticalScrollPosition():Number {
			return vScroll.value;
		}
		
		public function set verticalScrollPosition(value:Number):void {
			vScroll.onNext(Math.min(Math.max(value, 0), height - viewport.height));
		}
		
		public const hScroll:BehaviorSubject = new BehaviorSubject(0);
		public function get horizontalScrollPosition():Number {
			return hScroll.value;
		}
		
		public function set horizontalScrollPosition(value:Number):void {
			hScroll.onNext(Math.max(value, 0));
		}
		
		public function set viewport(value:Rectangle):void {
			_viewport.onNext(value);
		}
		
		public function get viewport():Rectangle {
			return _viewport.value;
		}
		
		public const cache:Virtualizer = new Virtualizer();
		
		private const _viewport:BehaviorSubject = new BehaviorSubject(new Rectangle());
		public const viewports:IObservable = _viewport.asObservable();
	}
}