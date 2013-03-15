package org.tinytlf.views
{
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import spark.core.IViewport;
	
	import asx.fn.args;
	import asx.fn.aritize;
	import asx.fn.getProperty;
	import asx.fn.noop;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.newInstance_;
	
	import org.tinytlf.lambdas.getNodeNameFromInheritance;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.procedures.applyNodeInheritance;
	import org.tinytlf.streams.emitVisibleRenderables;
	import org.tinytlf.streams.groupRenderableLifetimes;
	import org.tinytlf.streams.mapContainerRenderable;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Renderable;
	
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.subjects.BehaviorSubject;
	
	public class WebView extends UIComponent implements IViewport
	{
		public function WebView() {
			
			super();
			
			addParser('body', mapContainerRenderable);
			addParser('div', mapContainerRenderable);
			addParser('section', mapContainerRenderable);
			addParser('article', mapContainerRenderable);
			addParser('p', mapRedBoxRenderable);
			
			addUI('body', partial(newInstance_, TextContainer));
			addUI('div', partial(newInstance_, TextContainer));
			addUI('section', partial(newInstance_, TextContainer));
			addUI('article', partial(newInstance_, TextContainer));
			addUI('p', partial(newInstance_, RedBox));
			
			Observable.fromEvent(this, FlexEvent.CREATION_COMPLETE).first().subscribe(creationComplete);
		}
		
		private const region:Region = new Region(Observable.value(0), Observable.value(0));
		
		internal const cssSubj:BehaviorSubject = new BehaviorSubject(new CSS());
		public function get css():CSS {
			return cssSubj.value;
		}
		
		public function set css(value:*):void {
			cssSubj.onNext(value is CSS ? value : new CSS(value));
		}
		
		private const htmlSubj:BehaviorSubject = new BehaviorSubject();
		public function get html():XML {
			return htmlSubj.value;
		}
		
		public function set html(value:*):void {
			htmlSubj.onNext(value);
		}
		
		private function getUI(key:String):Function {
			return uis[getNodeNameFromInheritance(key)];
		}
		
		internal const uis:Object = {};
		
		public function addUI(type:String, fn:Function):WebView {
			uis[type] = fn;
			return this;
		}
		
		private function getParser(key:String):Function/*<IObservable<Rendered>>*/ {
			return parsers[getNodeNameFromInheritance(key)] || mapContainerRenderable;
		}
		
		internal const parsers:Object = {};
		
		public function addParser(type:String, fn:Function):WebView {
			parsers[type] = fn;
			return this;
		}
		
		override protected function createChildren():void {
			htmlSubj.distinctUntilChanged().
				combineLatest(cssSubj.distinctUntilChanged(), args).
				subscribe(sequence(aritize(invalidateSize, 0), aritize(invalidateDisplayList, 0)));
		}
		
		private function creationComplete(...args):void {
			
			const htmlDispatcher:ISubject = new Subject();
			
			const group:IGroupedObservable = new GroupedObservable('body', htmlDispatcher);
			
			CSS(cssSubj.value).inject('body {' +
				'width: ' + width + 'px;' +
				'height: ' + height + 'px;' +
			'}');
			
			const visible:IObservable = emitVisibleRenderables(htmlDispatcher, region.viewport, region.cache).
				publish().refCount();
			
			const lifetimes:IObservable = groupRenderableLifetimes(visible, region.viewport, region.cache).
				publish().
				refCount();
			
			lifetimes.
				mapMany(partial(mapContainerRenderable, region, getUI, getParser, cssSubj)).
				map(getProperty('display')).
				subscribe(addChild, noop, trace);
			
			htmlSubj.distinctUntilChanged().
				map(toXML).
				map(applyNodeInheritance).
				multicast(htmlDispatcher).
				connect();
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			region.width = w;
			region.height = h;
		}
		
		// TODO: layouts, measure content width, etc.
		private var cWidth:Number = 1000;
		public function get contentWidth():Number
		{
			return cWidth;
		}
		
		// TODO: layouts, measure content height, etc.
		private var cHeight:Number = 2000;
		public function get contentHeight():Number
		{
			return cHeight;
		}
		
		public function get horizontalScrollPosition():Number
		{
			return region.horizontalScrollPosition;
		}
		
		public function set horizontalScrollPosition(value:Number):void
		{
			region.horizontalScrollPosition = value;
		}
		
		public function get verticalScrollPosition():Number
		{
			return region.verticalScrollPosition;
		}
		
		public function set verticalScrollPosition(value:Number):void
		{
			region.verticalScrollPosition = value;
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

import flash.display.DisplayObject;

import asx.fn.K;
import asx.fn.args;
import asx.fn.aritize;
import asx.fn.distribute;
import asx.fn.partial;
import asx.fn.sequence;

import org.tinytlf.events.render;
import org.tinytlf.lambdas.sideEffect;
import org.tinytlf.lambdas.toStyleable;
import org.tinytlf.subscriptions.listenForUIRendered;
import org.tinytlf.types.CSS;
import org.tinytlf.types.Region;
import org.tinytlf.types.Renderable;
import org.tinytlf.views.TextContainer;

import raix.reactive.AbsObservable;
import raix.reactive.CompositeCancelable;
import raix.reactive.ICancelable;
import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.Observable;
import raix.reactive.scheduling.Scheduler;

internal class GroupedObservable extends AbsObservable implements IGroupedObservable {
	private var _underlyingObservable : IObservable;
	private var _key : Object;
	
	public function GroupedObservable(key : Object, underlyingObservable : IObservable)
	{
		_underlyingObservable = underlyingObservable;
		_key = key;			
	}
	
	public function get key() : Object
	{
		return _key;
	}
	
	public override function subscribeWith(observer:IObserver):ICancelable
	{
		return _underlyingObservable.subscribeWith(observer);
	}
}

internal class RedBox extends TextContainer
{
	public function RedBox(region:Region)
	{
		super(region);
	}
	
	override protected function draw():void {
		const w:Number = region.width;
		const h:Number = region.height;
		
		graphics.clear();
		graphics.beginFill(0xFF0000);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		
		super.draw();
	}
}

internal function mapRedBoxRenderable(parent:Region,
									  uiFactory:Function/*(String):Function(Region):DisplayObjectContainer*/,
									  childFactory:Function/*(String):Function(Region, Function, Function, IObservable<CSS>, IGroupedObservable<Renderable>):IObservable<Rendered>*/,
									  styles:IObservable/*<CSS>*/,
									  lifetime:IGroupedObservable/*<Renderable>*/):IObservable/*<Rendered>*/ {
	
	const region:Region = new Region(parent.vScroll, parent.hScroll);
	const ui:DisplayObject = uiFactory(lifetime.key)(region);
	const subscriptions:CompositeCancelable = new CompositeCancelable();
	
	return lifetime.combineLatest(styles, args).
		peek(distribute(sideEffect(partial(listenForUIRendered, ui, region.cache), subscriptions))).
		peek(distribute(function(renderable:Renderable, css:CSS):void {
			const node:XML = renderable.node;
			
			region.mergeWith(toStyleable(node, css));
			region.width = 90;
			region.height = 90;
			
			region.y = node.childIndex() * 100;
			
			ui.alpha = Math.max(0.05, node.childIndex() / 10);
		})).
		delay(0, Scheduler.greenThread).
		peek(sequence(K(render()), ui.dispatchEvent)).
		mapMany(distribute(aritize(function(renderable:Renderable):IObservable {
			return renderable.rendered.concat(Observable.never());
		}, 1))).
		
		takeUntil(lifetime.count()).
		// When this sequence terminates, clean up the child subscriptions.
		finallyAction(subscriptions.cancel);
}













