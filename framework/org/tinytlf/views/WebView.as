package org.tinytlf.views
{
	import flash.geom.Rectangle;
	
	import asx.fn.getProperty;
	import asx.fn.noop;
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import org.tinytlf.lambdas.getNodeNameFromInheritance;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.streams.mapContainerRenderable;
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
	import raix.reactive.subjects.IConnectableObservable;
	
	public class WebView extends TextContainer
	{
		public function WebView() {
			
			super(new Region(Observable.value(0), Observable.value(0)));
			
			addParser('body', org.tinytlf.streams.mapContainerRenderable);
			addParser('div', org.tinytlf.streams.mapContainerRenderable);
			addParser('section', org.tinytlf.streams.mapContainerRenderable);
			addParser('article', org.tinytlf.streams.mapContainerRenderable);
			addParser('p', org.tinytlf.streams.mapContainerRenderable);
			
			addUI('body', partial(newInstance_, TextContainer));
			addUI('div', partial(newInstance_, TextContainer));
			addUI('section', partial(newInstance_, TextContainer));
			addUI('article', partial(newInstance_, TextContainer));
			addUI('p', partial(newInstance_, RedBox));
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
			
			region.viewport.subscribe(function(rect:Rectangle):void {
				measuredWidth = rect.width;
				measuredHeight = rect.height;
			});
			
			const htmlSource:IConnectableObservable = htmlSubj.distinctUntilChanged().
				map(toXML).
				map(partial(newInstance_, Renderable)).
				publish();
			
			const group:IGroupedObservable = new GroupedObservable('body', htmlSource);
			
			org.tinytlf.streams.mapContainerRenderable(region, getUI, getParser, cssSubj, group).
				map(getProperty('display')).
				subscribe(addChild, noop, trace);
			
			htmlSource.connect();
		}
	}
}

import org.tinytlf.types.Region;
import org.tinytlf.views.TextContainer;

import raix.reactive.AbsObservable;
import raix.reactive.ICancelable;
import raix.reactive.IGroupedObservable;
import raix.reactive.IObservable;
import raix.reactive.IObserver;

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
	
	override protected function updateDisplayList(w:Number, h:Number):void {
		graphics.beginFill(0xCC0000);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		
		super.updateDisplayList(w, h);
	}
}
