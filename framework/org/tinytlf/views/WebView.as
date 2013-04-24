package org.tinytlf.views
{
	import asx.array.forEach;
	import asx.fn.K;
	import asx.fn.apply;
	import asx.fn.getProperty;
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	
	import org.tinytlf.fn.addInheritanceChain;
	import org.tinytlf.fn.toNameFromKey;
	import org.tinytlf.fn.toXML;
	import org.tinytlf.observables.Values;
	import org.tinytlf.observables.cacheObservable;
	import org.tinytlf.parsers.block.container;
	import org.tinytlf.parsers.block.br_block;
	import org.tinytlf.parsers.block.nope;
	import org.tinytlf.parsers.block.paragraph;
	import org.tinytlf.parsers.inline.br_inline;
	import org.tinytlf.parsers.inline.span;
	import org.tinytlf.parsers.inline.text;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	
	import spark.core.IViewport;
	
	import trxcllnt.gr.mouse.down;
	import trxcllnt.gr.mouse.move;
	import trxcllnt.gr.mouse.up;
	import trxcllnt.gr.terminators.stop;
	import trxcllnt.vr.Virtualizer;
	
	public class WebView extends UIComponent implements IViewport, TTLFView
	{
		public function WebView()
		{
			super();
			
			const invokeUI:Function = function(values:Values):DisplayObject {
				return getUIParser(values.key)(values);
			};
			
			const parsed:Object = {};
			
			const invokeBlockParser:Function = function(values:Values):IObservable {
				return getBlockParser(values.key)(values);
			};
			
			const invokeInlineParser:Function = function(values:Values):IObservable {
				return getInlineParser(values.key)(values);
			};
			
			const c:Function = function(parser:Function, ...args):Function {
				return partial(cacheObservable, parsed, partial.apply(null, [parser].concat(args)));
			}
			
			const containerParser:Function = c(container, invokeUI, invokeBlockParser);
			const paragraphParser:Function = c(paragraph, invokeUI, invokeBlockParser, invokeInlineParser);
			const spanParser:Function = c(span, invokeInlineParser);
			const textParser:Function = c(text);
			const blockLineBreakParser:Function = c(br_block);
			const inlineLineBreakParser:Function = c(br_inline);
			const nullParser:Function = c(nope);
			
			const containerUIFactory:Function = partial(newInstance_, Container);
			const paragraphUIFactory:Function = partial(newInstance_, Paragraph);
			
			// TODO: Add <style/>, <object/>, <a/>, <img/>, and <image/> parsers
			addBlockParser(nullParser, 'style', 'object', 'a', 'img', 'image').
			addInlineParser(nullParser, 'style', 'object', 'a', 'img', 'image').
			
			addBlockParser(containerParser, 'html', 'body', 'article', 'div', 'footer', 'header', 'section').
			addUIParser(containerUIFactory, 'html', 'body', 'article', 'footer', 'div', 'header', 'section').
			
			addBlockParser(containerParser, 'table', 'colgroup', 'col', 'tbody', 'tr', 'td').
			addUIParser(containerUIFactory, 'table', 'colgroup', 'col', 'tbody', 'tr', 'td').
			
			addBlockParser(paragraphParser, 'p', 'span', 'text').
			addUIParser(paragraphUIFactory, 'p', 'span', 'text').
			
			addInlineParser(spanParser, 'span').
			addInlineParser(textParser, 'text').
			
			addBlockParser(blockLineBreakParser, 'br').
			addInlineParser(inlineLineBreakParser, 'br');
			
			subscribeScroll();
			subscribeValues();
		}
		
		public function get children():Array {
			const kids:Array = [];
			for(var i:int = 0, n:int = numChildren; i < n; ++i) kids.push(getChildAt(i))
			return kids;
		}
		
		private var _element:Values = new Values({
			cache: new Virtualizer(),
			index: 0,
			key: 'html'
		}, 'cache', 'html', 'viewport', 'width', 'height', 'x', 'y');
		
		public function get element():Values {
			return _element;
		}
		
		public function get css():* {
			return null;
		}
		
		public function set css(value:*):void {
		}
		
		public function get html():XML {
			return element.html;
		}
		
		public function set html(value:*):void {
			element.html = addInheritanceChain(toXML(value));
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			if(initialized) return;
			
			element.width = w;
			element.height = h;
			element.viewport = new Rectangle(0, 0, w, h);
			
			// TODO: Parse/Observe
		}
		
		private var cWidth:Number = 1000;
		public function get contentWidth():Number {
			return cWidth;
		}
		
		private var cHeight:Number = 1000;
		public function get contentHeight():Number {
			return cHeight;
		}
		
		public function get horizontalScrollPosition():Number {
			return element.viewport.x;
		}
		
		public function set horizontalScrollPosition(value:Number):void {
			const viewport:Rectangle = element.viewport;
			viewport.x = value;
			element.viewport = viewport.clone();
		}
		
		public function get verticalScrollPosition():Number {
			return element.viewport.y;
		}
		
		public function set verticalScrollPosition(value:Number):void {
			const viewport:Rectangle = element.viewport;
			viewport.y = value;
			element.viewport = viewport.clone();
		}
		
		public function getHorizontalScrollPositionDelta(navigationUnit:uint):Number {
			return 10;
		}
		
		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number {
			return 10;
		}
		
		public function get clipAndEnableScrolling():Boolean {
			return true;
		}
		
		public function set clipAndEnableScrolling(value:Boolean):void {}
		
		// TODO: Clean this up
		private function subscribeScroll():ICancelable {
			
			const takeEvents:Function = function(...args):Boolean {
				return true;
//				return viewport.height < height
			};
			
			const self:IEventDispatcher = this;
			const downObs:IObservable = down(this);
			const upObs:IObservable = up(this);
			const dragObs:IObservable = downObs.mapMany(function(d:MouseEvent):IObservable {
				const moveObs:IObservable = trxcllnt.gr.mouse.move(stage);
				
				return moveObs.filter(takeEvents).
				peek(stop).
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
			
			const wheelY:IObservable = Observable.fromEvent(this, MouseEvent.MOUSE_WHEEL).
				filter(takeEvents).
				peek(stop).
				map(getProperty('delta'));
			
			return dragObs.merge(wheelY).
				subscribe(function(delta:Number):void {
					const rect:Rectangle = element.viewport.clone();
					rect.y -= delta;
					element.viewport = scrollRect = rect;
				});
		}
		
		private function subscribeValues():void {
			const parse:Function = getBlockParser('html');
			parse(element).subscribe(apply(function(values:Values, child:DisplayObjectContainer):void {
				if(contains(child)) return;
				
				addChild(child);
			}));
		}
		
		private const blockParsers:Object = {};
		private const inlineParsers:Object = {};
		private const uiParsers:Object = {};
		
		public function addBlockParser(value:Function, ...names):WebView {
			return addValue.apply(null, [blockParsers, value].concat(names));
		}
		
		public function addInlineParser(value:Function, ...names):WebView {
			return addValue.apply(null, [inlineParsers, value].concat(names));
		}
		
		public function addUIParser(value:Function, ...names):WebView {
			return addValue.apply(null, [uiParsers, value].concat(names));
		}
		
		public function getBlockParser(key:String):Function {
			return getValue(blockParsers, key);
		}
		
		public function getInlineParser(key:String):Function {
			return getValue(inlineParsers, key);
		}
		
		public function getUIParser(key:String):Function {
			return getValue(uiParsers, key);
		}
		
		private function addValue(dictionary:Object, value:*, ...names):WebView {
			forEach(names, function(name:String):void { dictionary[name] = value; });
			return this;
		}
		
		private function getValue(dictionary:Object, key:String):Function {
			const name:String = toNameFromKey(key);
			return dictionary.hasOwnProperty(name) ? dictionary[name] : K(null);
		}
	}
}