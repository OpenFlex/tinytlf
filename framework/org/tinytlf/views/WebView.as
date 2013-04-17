package org.tinytlf.views
{
	import asx.array.*;
	import asx.fn.*;
	import asx.object.*;
	
	import flash.display.DisplayObject;
	import flash.events.*;
	import flash.geom.*;
	
	import mx.core.UIComponent;
	import mx.events.*;
	
	import org.tinytlf.actors.*;
	import org.tinytlf.events.mouse.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.procedures.*;
	import org.tinytlf.types.*;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;
	
	import spark.core.*;
	
	import trxcllnt.vr.Virtualizer;
	
	public class WebView extends UIComponent implements IViewport, IDOMView
	{
		public function WebView() {
			
			super();
			
			addParser('body', container);
			addParser('div', container);
			addParser('section', container);
			addParser('article', container);
			addParser('p', paragraph);
			
			addUI('body', partial(newInstance_, Container));
			addUI('div', partial(newInstance_, Container));
			addUI('section', partial(newInstance_, Container));
			addUI('article', partial(newInstance_, Container));
			addUI('p', partial(newInstance_, Paragraph));
			
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
			}).
			map(getProperty('y'));
			
			const wheelY:IObservable = Observable.fromEvent(this, MouseEvent.MOUSE_WHEEL).map(getProperty('delta'));
			
			dragObs.merge(wheelY).subscribe(function(delta:Number):void {
				region.verticalScrollPosition -= delta;
			});
			
			Observable.fromEvent(this, MouseEvent.MOUSE_WHEEL).
				subscribe(function(e:MouseEvent):void {
					region.verticalScrollPosition -= e.delta;
				});
		}
		
		internal const cssSubj:BehaviorSubject = new BehaviorSubject(new CSS());
		public function get css():CSS {
			return cssSubj.value;
		}
		
		public function set css(value:*):void {
			cssSubj.onNext(value is CSS ? value : new CSS(value));
		}
		
		private const region:Region = new Region(Observable.value(0), Observable.value(0));
		private const _element:DOMElement = new DOMElement(region, 'body');
		
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
			return key ? uis[getNodeNameFromInheritance(key)] || K(null) : K(null);
		}
		
		internal const uis:Object = {};
		
		public function addUI(type:String, fn:Function):WebView {
			uis[type] = fn;
			return this;
		}
		
		private function getParser(key:String):Function/*:IObservable<Array<Unit, DisplayObject>>*/ {
			return parsers[getNodeNameFromInheritance(key)] || container;
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
			
			container(element, getUI, getParser).
				subscribe(distribute(function(e:DOMElement, container:DisplayObject):void {
					if(!contains(container)) addChild(container);
					
					const region:Region = e.region;
					const cache:Virtualizer = region.cache;
					
					var event:PropertyChangeEvent;
					
					const maxW:Number = max(container['children'], 'width') as Number;
					
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
				}));
			
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
