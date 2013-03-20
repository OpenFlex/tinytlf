package org.tinytlf.views
{
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import spark.core.IViewport;
	
	import asx.fn.getProperty;
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import org.tinytlf.actors.mapContainerRenderable;
	import org.tinytlf.actors.renderContainer;
	import org.tinytlf.handlers.printNext;
	import org.tinytlf.lambdas.getNodeNameFromInheritance;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.procedures.applyNodeInheritance;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.subjects.BehaviorSubject;
	
	public class WebView extends UIComponent implements IViewport
	{
		public function WebView() {
			
			super();
			
			addParser('body', renderContainer);
			addParser('div', renderContainer);
			addParser('section', renderContainer);
			addParser('article', renderContainer);
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
			const root:ISubject = new Subject();
			const body:DOMElement = new DOMElement('body');
			body.source = root;
			
			region.width = width;
			region.height = height;
			
			renderContainer(region, body, getUI, getParser, cssSubj.asObservable()).
				peek(printNext('root render')).
				map(getProperty('display')).
				peek(printNext('root render display')).
				subscribe(addChild);
			
			htmlSubj.distinctUntilChanged().
				map(toXML).
				map(applyNodeInheritance).
				multicast(root).
				connect();
		}
		
		// TODO: layouts, measure content width, etc.
		private var cWidth:Number = 1000;
		public function get contentWidth():Number
		{
			return cWidth;
		}
		
		// TODO: layouts, measure content height, etc.
		private var cHeight:Number = 13000;
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

import flash.display.DisplayObjectContainer;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import asx.fn.args;
import asx.fn.distribute;
import asx.object.isA;

import org.tinytlf.events.renderEvent;
import org.tinytlf.handlers.printComplete;
import org.tinytlf.handlers.printError;
import org.tinytlf.handlers.printNext;
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

import trxcllnt.ds.RTree;

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
		text.defaultTextFormat.align = TextFormatAlign.CENTER;
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
	
	override protected function draw():void {
		const w:Number = region.width;
		const h:Number = region.height;
		
		text.text = index + ' - ' + nodeIndex;
		
		graphics.clear();
		graphics.beginFill(0xFF0000);
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
			
			region.y = node.childIndex() * 100;
			
			ui.nodeIndex = node.childIndex();
			
//			ui.alpha = Math.max(0.05, node.childIndex() / 130);
			ui.alpha = Math.max(0.05, node.childIndex() / 10);
			
			ui.dispatchEvent(renderEvent());
			
			return new Rendered(updates, ui);
		})).
		peek(updateCacheAfterRender(parent.cache)).
		delay(1).
		peek(function(rendered:Rendered):void {
			updates.rendered.onNext(rendered);
			updates.rendered.onCompleted();
		}).
		takeUntil(updates.count());
}


