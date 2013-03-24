package org.tinytlf.views
{
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	
	import spark.core.IViewport;
	
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import org.tinytlf.actors.mapContainerRenderable;
	import org.tinytlf.actors2.renderDOMContainer;
	import org.tinytlf.lambdas.getNodeNameFromInheritance;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.procedures.applyNodeInheritance;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Rendered;
	
	import raix.reactive.Observable;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.ds.Envelope;
	
	public class WebView extends UIComponent implements IViewport
	{
		public function WebView() {
			
			super();
			
			addParser('body', renderDOMContainer);
			addParser('div', renderDOMContainer);
			addParser('section', renderDOMContainer);
			addParser('article', renderDOMContainer);
			addParser('p', renderRedBox);
			
			addUI('body', partial(newInstance_, TextContainer));
			addUI('div', partial(newInstance_, TextContainer));
			addUI('section', partial(newInstance_, TextContainer));
			addUI('article', partial(newInstance_, TextContainer));
			addUI('p', partial(newInstance_, RedBox));
			
			Observable.fromEvent(this, FlexEvent.UPDATE_COMPLETE).
				first().
				subscribe(onFirstUpdateDisplayList);
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
		
		private function onFirstUpdateDisplayList(...args):void {
			const body:DOMElement = new DOMElement('body');
			
			region.width = width;
			region.height = height;
			
			renderDOMContainer(region, body, getUI, getParser, cssSubj.asObservable()).
				subscribe(function(rendered:Rendered):void {
					
					const container:TextContainer = rendered.display as TextContainer;
					
					if(!contains(container)) {
						addChild(container);
					}
					
					const env:Envelope = container.region.cache.envelope;
					var event:PropertyChangeEvent;
					
					if(cWidth != env.width) {
						event = PropertyChangeEvent.createUpdateEvent(this, 'contentWidth', cWidth, env.width);
						cWidth = env.width;
						dispatchEvent(event);
					}
					if(cHeight != env.height) {
						event = PropertyChangeEvent.createUpdateEvent(this, 'contentHeight', cHeight, env.height);
						cHeight = env.height;
						dispatchEvent(event);
					}
					
					invalidateParentSizeAndDisplayList();
					invalidateDisplayList();
				});
			
			htmlSubj.distinctUntilChanged().
				map(toXML).
				map(applyNodeInheritance).
				multicast(body).
				connect();
		}
		
		// TODO: layouts, measure content width, etc.
		private var cWidth:Number = 0;
		public function get contentWidth():Number
		{
			return cWidth;
		}
		
		// TODO: layouts, measure content height, etc.
		private var cHeight:Number = 0;
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

import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import asx.fn.args;
import asx.fn.distribute;
import asx.number.snap;
import asx.object.isA;

import org.tinytlf.events.renderEvent;
import org.tinytlf.lambdas.toStyleable;
import org.tinytlf.lambdas.updateCacheAfterRender;
import org.tinytlf.types.CSS;
import org.tinytlf.types.DOMElement;
import org.tinytlf.types.Region;
import org.tinytlf.types.Rendered;
import org.tinytlf.views.TextContainer;

import raix.reactive.AbsObservable;
import raix.reactive.ICancelable;
import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.IObserver;
import raix.reactive.ISubject;

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
		
		text.defaultTextFormat = new TextFormat(null, 20);
		text.defaultTextFormat.align = TextFormatAlign.LEFT;
		text.autoSize = TextFieldAutoSize.NONE;
		text.width = 90;
		text.height = 90;
		
		index = ++times;
		
		addChild(text);
	}
	
	private const text:TextField = new TextField();
	
	private var index:int = 0;
	private static var times:int = -1;
	
	public var nodeIndex:int = -1;
	public var backgroundAlpha:Number = 0.05;
	
	override protected function draw():void {
		const w:Number = region.width;
		const h:Number = region.height;
		
		text.text = index + ' - ' + nodeIndex;
		text.x = (90 - text.width) * 0.5
		text.y = (90 - text.height) * 0.5
		
		graphics.clear();
		graphics.beginFill(0xFF0000, backgroundAlpha);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		
		super.draw();
	}
}

internal function renderRedBox(parent:Region,
							 updates:DOMElement/*<XML>*/,
							 uiFactory:Function/*<String>:<Function<Region>:<DisplayObjectContainer>>*/,
							 childFactory:Function,
							 styles:IObservable/*<CSS>*/):IObservable/*<Rendered>*/ {
	
	styles = styles.filter(isA(CSS));
	
	const region:Region = new Region(parent.vScroll, parent.hScroll);
	const ui:RedBox = uiFactory(updates.key)(region) as RedBox;
	
	const rendered:ISubject = updates.rendered;
	
	return updates.combineLatest(styles, args).
		map(distribute(function(node:XML, css:CSS):Rendered {
			
			region.mergeWith(toStyleable(node, css));
			region.width = 90;
			region.height = 90;
			
			const i:int = node.childIndex();
			region.x = i % 10 * 100;
			region.y = (Math.floor(i / 10) * 1) * 100;
			ui.nodeIndex = i;
			
			ui.backgroundAlpha = Math.max(0.05, node.childIndex() / 1000);
//			ui.alpha = Math.max(0.05, node.childIndex() / 10);
			
			ui.dispatchEvent(renderEvent());
			
			const rendered:Rendered = new Rendered(updates, ui);
			
			return rendered;
		})).
		peek(updateCacheAfterRender(parent.cache)).
		delay(10).
		peek(updates.rendered.onNext).
		takeUntil(updates.count());
}


