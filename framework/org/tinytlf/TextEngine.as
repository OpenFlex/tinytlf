package org.tinytlf
{
	import flash.display.*;
	import flash.system.*;
	
	import org.tinytlf.classes.CSS;
	import org.tinytlf.classes.Virtualizer;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Selection;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;

	public class TextEngine
	{
		public static const mac:Boolean = (/mac/i)['test'](Capabilities.os);
//		public static var stage:Stage;
		
		public function TextEngine()
		{
			super();
			
			// An Observable stream of block-level XML nodes.
			// An Observable stream of block-level XML node lifecycles.
			// An Observable stream of ContentElement lifecycles.
			// An Observable stream of TextBlock lifecycles.
			// An Observable stream of TextBlock lifecycles.
			// An Observable stream of Paragraph lifecycles.
			
			caretSubj.onNext(new Caret(null, null, null, -1, null));
			selectionSubj.onNext(new Selection(null, null));
			
			hScroll = 0;
			vScroll = 0;
		}
		
		private const contentDatabase:Virtualizer = new Virtualizer();
		private const layoutDatabase:Virtualizer = new Virtualizer();
		
		public function onError(e:Error):void {
			trace(e.getStackTrace());
		}
		
		private function castInner(type:Class):Function {
			return function(o:IObservable):IObservable {
				return o.cast(type);
			}
		};
		
		private var started:Boolean = false;
		public const subscriptions:CompositeCancelable = new CompositeCancelable();
		
		public function start(stage:Stage):void {
			if(started) stop();
			started = true;
			
//			subscriptions.add(htmlBlockElementObs.subscribe(xmlNodesSubj.onNext, null, onError));
			
			// Set up the blocks linked-list
//			subscriptions.add(blocks.skip(1).zip(blocks, concatParams).
//				mapMany(function(a:Array):IObservable {
//					const prev:IObservable = a.pop();
//					const now:IObservable = a.pop();
//					return now.zip(prev, concatParams).take(1);
//				}).
//				subscribe(function(a:Array):void {
//					const prev:Block = a.pop();
//					const now:Block = a.pop();
//					prev.next = now;
//					now.prev = prev;
//				}));
			
			// Set up the Paragraphs linked list
//			subscriptions.add(paragraphs.skip(1).zip(paragraphs, concatParams).
//				mapMany(function(a:Array):IObservable {
//					const prev:IObservable = a.pop();
//					const now:IObservable = a.pop();
//					return now.zip(prev, concatParams).take(1);
//				}).
//				subscribe(function(a:Array):void {
//					const prev:Paragraph = a.pop();
//					const now:Paragraph = a.pop();
//					prev.next = now;
//					now.prev = prev;
//				}));
		}
		
		public function stop():void {
			started = false;
			contentDatabase.clear()
			layoutDatabase.clear();
			subscriptions.cancel();
		}
		
		private const htmlSubj:ISubject = new ReplaySubject(1);
		
		public function get html():IObservable {
			return htmlSubj.map(toXML).
				distinctUntilChanged().
				cast(XML);
		}
		
		public function set html(w:*):void {
			htmlSubj.onNext(w);
		}
		
		public function setHtml(w:*):void {
			this.html = w;
		}
		
		private const cssSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of CSS values.
		 */
		public function get css():IObservable {
			return cssSubj.cast(CSS);
		}
		
		public function set css(w:*):void {
			cssSubj.onNext(w is CSS ? w : new CSS(w));
		}
		
		public function setCss(w:*):void {
			this.css = w;
		}
		
		private const hScrollSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of x-scroll positions.
		 */
		public function get hScroll():IObservable {
			return hScrollSubj.distinctUntilChanged().cast(Number);
		}
		
		public function set hScroll(w:*):void {
			hScrollSubj.onNext(w);
		}
		
		public function setHScroll(w:*):void {
			this.hScroll = w;
		}
		
		private const vScrollSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of y-scroll positions.
		 */
		public function get vScroll():IObservable {
			return vScrollSubj.distinctUntilChanged().cast(Number);
		}
		
		public function set vScroll(w:*):void {
			vScrollSubj.onNext(w);
		}
		
		public function setVScroll(w:*):void {
			this.vScroll = w;
		}
		
		private const widthSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of widths.
		 */
		public function get width():IObservable {
			return widthSubj.
				filter(function(val:Number):Boolean { return val > 50; }).
				distinctUntilChanged().
				cast(Number);
		}
		
		public function set width(w:*):void {
			widthSubj.onNext(w);
		}
		
		public function setWidth(w:*):void {
			this.width = w;
		}
		
		private const heightSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of heights.
		 */
		public function get height():IObservable {
			return heightSubj.
				distinctUntilChanged().
				cast(Number);
		}
		
		public function set height(w:*):void {
			heightSubj.onNext(w);
		}
		
		public function setHeight(w:*):void {
			this.height = w;
		}
		
		private const caretSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of Caret values.
		 */
		public function get caret():IObservable {
			return caretSubj.distinctUntilChanged().cast(Caret);
		}
		
		public function set caret(w:*):void {
			caretSubj.onNext(w);
		}
		
		public function setCaret(w:*):void {
			this.caret = w;
		}
		
		private const selectionSubj:ISubject = new ReplaySubject(1);
		
		/**
		 * An Observable stream of Selection values.
		 */
		public function get selection():IObservable {
			return selectionSubj.distinctUntilChanged().cast(Selection);
		}
		
		public function set selection(w:*):void {
			selectionSubj.onNext(w);
		}
		
		public function setSelection(w:*):void {
			this.selection = w;
		}
	}
}