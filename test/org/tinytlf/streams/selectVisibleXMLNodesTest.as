package org.tinytlf.streams
{
	import asx.fn.I;
	import asx.fn._;
	import asx.fn.aritize;
	import asx.fn.getProperty;
	import asx.fn.guard;
	import asx.fn.partial;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.fail;
	import org.flexunit.async.Async;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;
	import raix.reactive.scheduling.Scheduler;
	import raix.reactive.subjects.IConnectableObservable;

	public class selectVisibleXMLNodesTest extends StreamTest
	{
		public function selectVisibleXMLNodesTest()
		{
			super();
		}
		
		private const nodes:Array = [
			<div id="first">foo</div>,
			<div id="second">bar</div>,
			<div id="third">foobar</div>
		];
		
		[Test(async)]
		public function fxnDispatchesAllNodesWhenNoneAreRendered():void {
			
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			const visibleNodes:IConnectableObservable = emitVisibleRenderables(xml, viewport, cache).publish();
			
			visibleNodes.connect();
			
			visibleNodes.
				peek(cacheNodeKeys(cache)).
				take(nodes.length).
				map(getProperty('node')).
				all(function(node:XML):Boolean {
					return nodes.indexOf(node) != -1;
				}).
				subscribe(aritize(asyncHandler, 0), null, fail);
			
			nodes.forEach(guard(xml.onNext));
		}
		
		[Test(async)]
		public function fxnPullsVisibleNodesFromLayoutCache():void {
			
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			const visibleNodesObs:IObservable = emitVisibleRenderables(xml, viewport, cache)
			
			const firstVisiblePass:IConnectableObservable = visibleNodesObs.publish();
			firstVisiblePass.connect();
			
			firstVisiblePass.
				peek(cacheNodeKeys(cache)).
				take(nodes.length).
				subscribe(I, function():void {
					
					const secondVisiblePass:IConnectableObservable = visibleNodesObs.publish();
					
					secondVisiblePass.
						peek(cacheNodeKeys(cache)).
						take(2).
						map(getProperty('node')).
						all(function(node:XML):Boolean {
							return nodes.indexOf(node) != -1;
						}).
						subscribe(aritize(asyncHandler, 0), null, fail);
					
					secondVisiblePass.connect();
				});
			
			nodes.forEach(guard(xml.onNext));
		}
		
		[Test(async)]
		public function fxnIgnoresUpdatesWhenVisibleNodesStayTheSame():void {
			
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			const visibleNodes:IConnectableObservable = emitVisibleRenderables(xml, viewport, cache).publish();
			
			visibleNodes.connect();
			
			visibleNodes.
				peek(cacheNodeKeys(cache)).
				// Skip the initial nodes.
				skip(nodes.length).
				// Wait 250 ms to see if we hear any more messages.
				timeout(250).
				// If we do, fail. If we don't, assert true
				subscribe(partial(fail, ''), I, aritize(asyncHandler, 0));
			
			nodes.forEach(guard(xml.onNext));
			
			viewport.onNext(dimensions);
		}
		
		[Test(async)]
		public function fxnUpdatesWhenViewportChanges():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			const visibleNodesObs:IConnectableObservable = emitVisibleRenderables(xml, viewport, cache).publish();
			
			visibleNodesObs.connect();
			
			visibleNodesObs.
				peek(cacheNodeKeys(cache)).
				// Skip the initial nodes, take the last two, count them.
				skip(nodes.length).take(2).count().
				subscribe(
					partial(assertEquals, 2, _),
					asyncHandler,
					fail
				);
			
			nodes.forEach(guard(xml.onNext));
			
			Scheduler.immediate.schedule(function():void {
				dimensions.y = 100;
				viewport.onNext(dimensions);
			}, 100);
		}
	}
}