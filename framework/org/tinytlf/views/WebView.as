package org.tinytlf.views
{
	import flash.geom.Rectangle;
	
	import asx.fn.getProperty;
	
	import org.tinytlf.enum.TextBlockProgression;
	import org.tinytlf.lambdas.getNodeNameFromInheritance;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.streams.mapContainerRenderable;
	import org.tinytlf.streams.mapParagraphRenderable;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Renderable;
	
	import raix.reactive.GroupedObservable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.subjects.BehaviorSubject;
	
	public class WebView extends TextContainer
	{
		public function WebView() {
			
			super(new Region(Observable.value(0), Observable.value(0)));
			
			addParser('body', mapContainerRenderable);
			addParser('div', mapContainerRenderable);
			addParser('section', mapContainerRenderable);
			addParser('article', mapContainerRenderable);
			addParser('p', mapParagraphRenderable);
		}
		
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
		
		override protected function createChildren():void {
			
			region.viewport.subscribe(function(rect:Rectangle):void {
				width = rect.width;
				height = rect.height;
			});
			
			cssSubj.subscribe(function(css:CSS):void {
				const direction:String = TextBlockProgression.convert(css.getStyle('textDirection'));
//				layout = direction == TextBlockProgression.TTB ?
//					new VerticalLayout() :
//					new HorizontalLayout();
			});
			
			const mapRenderable:Function = function(xml:XML):Renderable {
				return new Renderable(xml);
			};
			
			const group:IGroupedObservable = new GroupedObservable('body', htmlSubj.
				map(toXML).
				map(mapRenderable));
			
			const bodyDisplay:IObservable = mapContainerRenderable(region, getUI, getParser, cssSubj, group);
			
			bodyDisplay.map(getProperty('display')).subscribe(addChild);
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
	}
}