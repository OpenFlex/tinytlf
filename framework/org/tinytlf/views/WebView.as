package org.tinytlf.views
{
	import asx.array.*;
	import asx.fn.*;
	import asx.object.*;
	
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
			
			region.element = element;
			
			addParser('body', renderDOMContainer);
			addParser('div', renderDOMContainer);
			addParser('section', renderDOMContainer);
			addParser('article', renderDOMContainer);
			addParser('p', renderDOMParagraph);
			
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
			return key ? uis[getNodeNameFromInheritance(key)] || K(null) : K(null);
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
			
			const childRegion:Region = new Region(region.vScroll, region.hScroll);
			childRegion.width = width;
			childRegion.height = height;
			childRegion.viewport = region.viewport = new Rectangle(0, 0, width, height);
			
			renderDOMContainer(childRegion, element, getUI, getParser, cssSubj.asObservable()).
				peek(updateCacheAfterRender(region.cache)).
				// Notify the current rendered subject of completion.
				peek(sequence(
					element.rendered.onNext,
					aritize(element.rendered.onCompleted, 0)
				)).
				subscribe(function(rendered:Rendered):void {
					
					const container:Container = rendered.display as Container;
					
					if(!contains(container)) {
						addChild(container);
					}
					
					const cache:Virtualizer = childRegion.cache;
					const viewport:Rectangle = childRegion.viewport;
					
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
