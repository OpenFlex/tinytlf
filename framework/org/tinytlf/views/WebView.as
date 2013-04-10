package org.tinytlf.views
{
	import asx.array.*;
	import asx.fn.*;
	import asx.object.*;
	
	import flash.events.*;
	import flash.geom.*;
	
	import mx.core.*;
	import mx.events.*;
	
	import org.tinytlf.actors.*;
	import org.tinytlf.events.mouse.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.procedures.*;
	import org.tinytlf.types.*;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;
	
	import spark.core.*;
	
	public class WebView extends UIComponent implements IViewport, IDOMView
	{
		public function WebView() {
			
			super();
			
			region.element = element;
			
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
			
			const self:WebView = this;
			const downObs:IObservable = down(this);
			const upObs:IObservable = up(this);
			const dragObs:IObservable = downObs.mapMany(function(d:MouseEvent):IObservable {
				const moveObs:IObservable = org.tinytlf.events.mouse.move(self);
				
				return moveObs.startWith(d).
					scan(function(o:Object, m:MouseEvent):Object {
						return {
							x: m.stageX,
							y: m.stageY,
							dx: m.stageX - o.x,
							dy: m.stageY - o.y
						};
					}, {x: d.stageX, y: d.stageY}, true).
					map(function(o:Object):Point {
						return new Point(o.dx, o.dy);
					}).
					takeUntil(upObs);
			});
			
			dragObs.subscribe(function(delta:Point):void {
				region.verticalScrollPosition -= delta.y;
			});
			
			Observable.fromEvent(this, MouseEvent.MOUSE_WHEEL).
				subscribe(function(e:MouseEvent):void {
					region.verticalScrollPosition -= e.delta;
				});
		}
		
		private const region:Region = new Region(Observable.value(0), Observable.value(0));
		
		internal const cssSubj:BehaviorSubject = new BehaviorSubject(new CSS());
		public function get css():CSS {
			return cssSubj.value;
		}
		
		public function set css(value:*):void {
			cssSubj.onNext(value is CSS ? value : new CSS(value));
		}
		
		private const _element:DOMElement = new DOMElement('body');
		public function get element():DOMElement {
			return _element;
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
			return parsers[getNodeNameFromInheritance(key)] || renderDOMContainer;
		}
		
		internal const parsers:Object = {};
		
		public function addParser(type:String, fn:Function):WebView {
			parsers[type] = fn;
			return this;
		}
		
		private function onFirstUpdateDisplayList(...args):void {
			region.width = width;
			region.height = height;
			region.viewport = new Rectangle(0, 0, width, height);
			
			renderDOMContainer(region, element, getUI, getParser, cssSubj.asObservable()).
				subscribe(function(rendered:Rendered):void {
					
					const container:TextContainer = rendered.display as TextContainer;
					
					if(!contains(container)) {
						addChild(container);
					}
					
					const cache:Virtualizer = container.region.cache;
					const viewport:Rectangle = container.region.viewport;
					const visible:Array = cache.slice(viewport.y, viewport.bottom);
					
					var event:PropertyChangeEvent;
					
					const maxW:Number = max(container.children, 'width') as Number;
					
					if(cWidth != maxW) {
						event = PropertyChangeEvent.createUpdateEvent(this, 'contentWidth', cWidth, maxW);
						cWidth = maxW;
						dispatchEvent(event);
					}
					if(cHeight != cache.size) {
						event = PropertyChangeEvent.createUpdateEvent(this, 'contentHeight', cHeight, cache.size);
						cHeight = cache.size;
						dispatchEvent(event);
					}
					
					region.height = cHeight;
					region.width = cWidth;
					
					graphics.clear();
					graphics.lineStyle(1, 0x00, 0.25);
					graphics.beginFill(0x00, 0);
					graphics.drawRect(0, 0, width, height);
					graphics.endFill();
					
					invalidateParentSizeAndDisplayList();
					invalidateDisplayList();
				});
			
			htmlSubj.distinctUntilChanged().
				map(toXML).
				map(applyNodeInheritance).
				subscribe(element.update);
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

import asx.array.map;
import asx.array.range;
import asx.fn.args;
import asx.fn.aritize;
import asx.fn.distribute;
import asx.fn.sequence;
import asx.number.sum;
import asx.object.isA;

import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

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
		text.autoSize = TextFieldAutoSize.NONE;
		text.selectable = false;
		
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
		
		this.name = text.text = nodeIndex.toString();// + ' - ' + index;
		text.x = (w - text.textWidth) * 0.5;
		text.y = (h - text.textHeight) * 0.5;
		
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
	region.element = updates;
	
	const ui:RedBox = uiFactory(updates.key)(region) as RedBox;
	
	const rendered:ISubject = updates.rendered;
	
	return updates.combineLatest(styles, args).
		map(distribute(function(node:XML, css:CSS):Rendered {
			
			region.mergeWith(toStyleable(node, css));
			
			const i:int = node.childIndex();
			ui.nodeIndex = i;
			
			region.width = 700 * ((i + 1) / 10);
			region.height = 250 * ((i + 1) / 10);
			region.viewport = new Rectangle(0, 0, region.width, region.height);
			
			region.x = 0;
			region.y = sum(map(range(0, i), function(i:int):Number {
				return 250 * ((i + 1) / 10);
			}));
			
//			ui.backgroundAlpha = Math.max(0.05, i / 10);
			ui.backgroundAlpha = 0.25;
			
			ui.dispatchEvent(renderEvent());
			
			const rendered:Rendered = new Rendered(updates, ui);
			
			return updateCacheAfterRender(parent.cache)(rendered);
		})).
		delay(10).
		peek(sequence(
			rendered.onNext,
			aritize(rendered.onCompleted, 0)
		)).
		takeUntil(updates.count());
}


