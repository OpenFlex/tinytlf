package org.tinytlf.types
{
	import flash.geom.Rectangle;
	
	import asx.fn.args;
	import asx.fn.distribute;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.ds.RTree;
	
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
			
			pvScroll.combineLatest(ySubj, args).
				map(distribute(parentMinusChild)).
				filter(greaterThan0).
				combineLatest(vScroll, parentPlusChild).
				subscribeWith(vScroll);
			
			phScroll.combineLatest(xSubj, args).
				map(distribute(parentMinusChild)).
				filter(greaterThan0).
				combineLatest(hScroll, parentPlusChild).
				subscribeWith(hScroll);
			
			hScroll.
				combineLatest(vScroll, args).
				combineLatest(widthSubj, args).
				combineLatest(heightSubj, args).
				map(distribute(function(x:Number, y:Number, w:Number, h:Number):Rectangle {
					return new Rectangle(x, y, w, h);
				})).
				multicast(viewport as ISubject).
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
		
		public const vScroll:BehaviorSubject = new BehaviorSubject(0);
		public function get verticalScrollPosition():Number {
			return vScroll.value;
		}
		
		public function set verticalScrollPosition(value:Number):void {
			vScroll.onNext(value);
		}
		
		public const hScroll:BehaviorSubject = new BehaviorSubject(0);
		public function get horizontalScrollPosition():Number {
			return hScroll.value;
		}
		
		public function set horizontalScrollPosition(value:Number):void {
			hScroll.onNext(value);
		}
		
		public const cache:IObservable = new BehaviorSubject(new RTree());
		public const viewport:IObservable = new BehaviorSubject(new Rectangle());
	}
}