package org.tinytlf.streams
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import asx.fn.I;
	import asx.fn.guard;
	import asx.fn.partial;
	
	import org.flexunit.assertThat;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertTrue;
	import org.flexunit.async.Async;
	import org.tinytlf.lambdas.deriveNodeInheritance;
	
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.subjects.IConnectableObservable;

	public class visibleXMLLifetimesTest extends StreamTest
	{
		public function visibleXMLLifetimesTest()
		{
			super();
		}
		
		private const body:XML = <body>
			<div id="first">foo</div>
			<div id="second">bar</div>
			<div id="third">foobar</div>
		</body>;
		
		private const nodes:Array = [
			body.children()[0],
			body.children()[1],
			body.children()[2],
		];
		
		[Test(async)]
		public function visibleXMLNodesGetLifetimes():void {
			
			const xml:IObservable = iterateXMLChildren(body).concat(Observable.never());
			const visibleNodes:IObservable = emitVisibleRenderables(xml, viewport, layout);
			const nodeLifetimes:IObservable = groupRenderableLifetimes(visibleNodes, viewport, layout);
			
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			nodeLifetimes.subscribe(function(group:IGroupedObservable):void {
				const index:int = nodes.
					map(guard(deriveNodeInheritance)).
					indexOf(group.key);
				
				assertNotNull(group);
				assertThat(index != -1);
				
				asyncHandler();
			});
		}
		
		[Test(async)]
		public function visibleXMLNodeLifetimesUpdateOnViewportChange():void {
			
			const xml:IObservable = iterateXMLChildren(body).concat(Observable.never());
			
			const visibleNodes:IObservable = emitVisibleRenderables(xml, viewport, layout).peek(cacheNodeKeys(tree));
			const nodeLifetimes:IObservable = groupRenderableLifetimes(visibleNodes, viewport, layout);
			
			const completedHandler:Function = Async.asyncHandler(this, partial(assertTrue, true), 500);
			const failDispatcher:IEventDispatcher = new EventDispatcher();
			Async.failOnEvent(this, failDispatcher, 'fail');
			
			nodeLifetimes.filter(function(group:IGroupedObservable):Boolean {
				return group.key == 'div#first:0';
			}).
			subscribe(function(group:IGroupedObservable):void {
				group.subscribe(I, completedHandler);
			});
			
			dimensions.y = 100;
			viewport.onNext(dimensions);
		}
	}
}