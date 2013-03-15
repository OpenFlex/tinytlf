package org.tinytlf.streams
{
	import flash.geom.Rectangle;
	
	import asx.fn.I;
	import asx.fn.getProperty;
	import asx.fn.partial;
	
	import org.flexunit.assertThat;
	import org.flexunit.asserts.fail;
	import org.flexunit.async.Async;
	import org.tinytlf.enum.TextBlockProgression;
	import org.tinytlf.types.Renderable;
	
	import raix.reactive.IGroupedObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Subject;
	import raix.reactive.scheduling.Scheduler;

	public class groupRenderableLifetimesTest extends StreamTest
	{
		public function groupRenderableLifetimesTest()
		{
			super();
		}
		
		[Test(async)]
		public function fxnCreatesLifetimeForNewXMLNode():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			groupRenderableLifetimes(xml, viewport, cache).
				subscribe(function(group:IGroupedObservable):void {
					assertThat(group != null);
					asyncHandler();
				});
			
			xml.onNext(new Renderable(<body/>));
		}
		
		[Test(async)]
		public function fxnDispatchesUpdateOnLifetimeForXMLNode():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			groupRenderableLifetimes(xml, viewport, cache).
				subscribe(function(body:IGroupedObservable):void {
					body.
						map(getProperty('node')).
						bufferWithCount(2).
						subscribe(
							function(bodies:Array):void {
								assertThat(bodies.length == 2);
								assertThat(bodies[0] == <body>foo</body>);
								assertThat(bodies[1] == <body><div/></body>);
								asyncHandler();
							},
							partial(fail, "The body group shouldn't have completed."),
							partial(fail, 'An error occurred.')
						);
				});
			
			xml.onNext(new Renderable(<body>foo</body>));
			xml.onNext(new Renderable(<body><div/></body>));
		}
		
		[Test(async)]
		public function fxnTerminatesLifetimeForEmptyXMLNode():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			groupRenderableLifetimes(xml, viewport, cache).
				subscribe(function(body:IGroupedObservable):void {
					body.subscribe(I, asyncHandler, partial(fail, 'An error occurred.'));
				});
			
			xml.onNext(new Renderable(<body>foo</body>));
			xml.onNext(new Renderable(<body/>));
		}
		
		[Test(async)]
		public function fxnTerminatesLifetimeWhenNodeScrolledOffScreenWithVerticalProgression():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			css.setStyle('textDirection', TextBlockProgression.TTB);
			
			groupRenderableLifetimes(xml, viewport, cache).
				subscribe(function(group:IGroupedObservable):void {
					cache.insert(group.key, new Rectangle(0, 0, 50, 50));
					
					group.subscribe(I, asyncHandler, partial(fail, 'An error occurred.'));
					
					Scheduler.immediate.schedule(function():void {
						dimensions.y = 100;
						viewport.onNext(dimensions);
					}, 100);
				});
			
			xml.onNext(new Renderable(<body>foo</body>));
		}
		
		[Test(async)]
		public function fxnTerminatesLifetimeWhenNodeScrolledOffScreenWithHorizontalProgression():void {
			const xml:ISubject = new Subject();
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			css.setStyle('textDirection', TextBlockProgression.LTR);
			
			groupRenderableLifetimes(xml, viewport, cache).
				subscribe(function(group:IGroupedObservable):void {
					cache.insert(group.key, new Rectangle(0, 0, 50, 50));
					
					group.subscribe(I, asyncHandler, partial(fail, 'An error occurred.'));
					
					Scheduler.immediate.schedule(function():void {
						dimensions.x = 100;
						viewport.onNext(dimensions);
					}, 100);
				});
			
			xml.onNext(new Renderable(<body>foo</body>));
		}
	}
}