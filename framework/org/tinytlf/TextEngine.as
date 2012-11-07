package org.tinytlf
{
	import flash.display.*;
	import flash.system.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.classes.CSS;
	import org.tinytlf.classes.Virtualizer;
	import org.tinytlf.lambdas.toXML;
	import org.tinytlf.streams.BlocksStream;
	import org.tinytlf.streams.ContentsStream;
	import org.tinytlf.streams.HTMLBlockElementStream;
	import org.tinytlf.streams.IStream;
	import org.tinytlf.streams.LinesStream;
	import org.tinytlf.streams.NodesStream;
	import org.tinytlf.streams.ParagraphsStream;
	import org.tinytlf.values.Block;
	import org.tinytlf.values.Caret;
	import org.tinytlf.values.Content;
	import org.tinytlf.values.Paragraph;
	import org.tinytlf.values.Selection;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;

	public class TextEngine extends Injector
	{
		public static const mac:Boolean = (/mac/i).test(Capabilities.os);
		public static var stage:Stage;
		
		public function TextEngine()
		{
			super();
			
			map(Injector).toValue(this);
			map(TextEngine).toValue(this);
			map(Virtualizer).asSingleton();
			
			// An Observable stream of inputs.
			map(ISubject, 'html').toValue(htmlSubj);
			map(IObservable, 'html').toValue(html);
			
			// An Observable stream of CSS.
			map(ISubject, 'css').toValue(cssSubj);
			map(IObservable, 'css').toValue(css);
			
			// An Observable stream of x-scroll positions.
			map(ISubject, 'hScroll').toValue(hScrollSubj);
			map(IObservable, 'hScroll').toValue(hScroll);
			
			// An Observable stream of x-scroll positions.
			map(ISubject, 'vScroll').toValue(vScrollSubj);
			map(IObservable, 'vScroll').toValue(vScroll);
			
			// An Observable stream of widths.
			map(ISubject, 'width').toValue(widthSubj);
			map(IObservable, 'width').toValue(width);
			
			// An Observable stream of heights.
			map(ISubject, 'height').toValue(heightSubj);
			map(IObservable, 'height').toValue(height);
			
			// An Observable stream of Caret values.
			caretSubj.onNext(new Caret(null, null, null, -1, null));
			map(ISubject, 'caret').toValue(caretSubj);
			map(IObservable, 'caret').toValue(caret);
			
			// An Observable stream of Caret values.
			selectionSubj.onNext(new Selection(null, null));
			map(ISubject, 'selection').toValue(selectionSubj);
			map(IObservable, 'selection').toValue(selection);
			
			// An Observable stream of block-level XML nodes.
			const xmlNodesSubj:ISubject = new Subject();
			map(ISubject, 'xml').toValue(xmlNodesSubj);
			map(IObservable, 'xml').toValue(xmlNodesSubj.cast(XML));
			
			hScroll = 0;
			vScroll = 0;
			
			map(Object, 'block').toValue({});
			map(Object, 'inline').toValue({});
			
			const htmlBlockElementObs:IObservable = IStream(instantiateUnmapped(HTMLBlockElementStream)).observable;
			map(IObservable, 'htmlBlockElements').toValue(htmlBlockElementObs.cast(XML));
			
			// An Observable stream of block-level XML node lifecycles.
			const nodesObs:IObservable = IStream(instantiateUnmapped(NodesStream)).observable;
			if(hasMapping(IObservable, 'nodes')) unmap(IObservable, 'nodes');
			map(IObservable, 'nodes').toValue(nodesObs.map(castInner(XML)));
			
			// An Observable stream of ContentElement lifecycles.
			const contentsObs:IObservable = IStream(instantiateUnmapped(ContentsStream)).observable;
			if(hasMapping(IObservable, 'contents')) unmap(IObservable, 'contents');
			map(IObservable, 'contents').toValue(contentsObs.map(castInner(Content)));
			
			// An Observable stream of TextBlock lifecycles.
			const blocksObs:IObservable = IStream(instantiateUnmapped(BlocksStream)).observable;
			if(hasMapping(IObservable, 'blocks')) unmap(IObservable, 'blocks');
			map(IObservable, 'blocks').toValue(blocksObs.map(castInner(Block)));
			
			// An Observable stream of TextBlock lifecycles.
			const linesObs:IObservable = IStream(instantiateUnmapped(LinesStream)).observable;
			if(hasMapping(IObservable, 'lines')) unmap(IObservable, 'lines');
			map(IObservable, 'lines').toValue(linesObs.map(castInner(Array)));
			
			// An Observable stream of Paragraph lifecycles.
			const paragraphsObs:IObservable = IStream(instantiateUnmapped(ParagraphsStream)).observable;
			if(hasMapping(IObservable, 'paragraphs')) unmap(IObservable, 'paragraphs');
			map(IObservable, 'paragraphs').toValue(paragraphsObs.map(castInner(DisplayObject)));
		}
		
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
		
		public function startup():void {
			if(started) return;
			started = true;
			
			const htmlBlockElementObs:IObservable = getInstance(IObservable, 'htmlBlockElements');
			const xmlNodesSubj:ISubject = getInstance(ISubject, 'xml');
			const blocks:IObservable = getInstance(IObservable, 'blocks');
			const paragraphs:IObservable = getInstance(IObservable, 'paragraphs');
			
			subscriptions.add(htmlBlockElementObs.subscribe(xmlNodesSubj.onNext, null, onError));
			
			// Set up the blocks linked-list
			subscriptions.add(blocks.skip(1).zip(blocks, [].concat).
				mapMany(function(a:Array):IObservable {
					const prev:IObservable = a.pop();
					const now:IObservable = a.pop();
					return now.zip(prev, [].concat).take(1);
				}).
				subscribe(function(a:Array):void {
					const prev:Block = a.pop();
					const now:Block = a.pop();
					prev.next = now;
					now.prev = prev;
				}));
			
			// Set up the Paragraphs linked list
			subscriptions.add(paragraphs.skip(1).zip(paragraphs, [].concat).
				mapMany(function(a:Array):IObservable {
					const prev:IObservable = a.pop();
					const now:IObservable = a.pop();
					return now.zip(prev, [].concat).take(1);
				}).
				subscribe(function(a:Array):void {
					const prev:Paragraph = a.pop();
					const now:Paragraph = a.pop();
					prev.next = now;
					now.prev = prev;
				}));
		}
		
		override public function teardown():void {
			
			const xmlNodesSubj:ISubject = getInstance(ISubject, 'xml');
			xmlNodesSubj.onCompleted();
			
			const virtualizer:Virtualizer = getInstance(Virtualizer);
			virtualizer.clear();
			
			subscriptions.cancel();
			
			super.teardown();
		}
		
		private const htmlSubj:ISubject = new ReplaySubject(1);
		
		public function get html():IObservable {
			return htmlSubj.map(toXML).cast(XML);
		}
		
		public function set html(w:*):void {
			htmlSubj.onNext(w);
		}
		
		private const cssSubj:ISubject = new ReplaySubject(1);
		
		public function get css():IObservable {
			return cssSubj.cast(CSS);
		}
		
		public function set css(w:*):void {
			cssSubj.onNext(w is CSS ? w : new CSS(w));
		}
		
		private const hScrollSubj:ISubject = new ReplaySubject(1);
		
		public function get hScroll():IObservable {
			return hScrollSubj.cast(Number);
		}
		
		public function set hScroll(w:*):void {
			hScrollSubj.onNext(w);
		}
		
		private const vScrollSubj:ISubject = new ReplaySubject(1);
		
		public function get vScroll():IObservable {
			return vScrollSubj.cast(Number);
		}
		
		public function set vScroll(w:*):void {
			vScrollSubj.onNext(w);
		}
		
		private const widthSubj:ISubject = new ReplaySubject(1);
		
		public function get width():IObservable {
			return widthSubj.cast(Number);
		}
		
		public function set width(w:*):void {
			widthSubj.onNext(w);
		}
		
		private const heightSubj:ISubject = new ReplaySubject(1);
		
		public function get height():IObservable {
			return heightSubj.cast(Number);
		}
		
		public function set height(w:*):void {
			heightSubj.onNext(w);
		}
		
		private const caretSubj:ISubject = new ReplaySubject(1);
		
		public function get caret():IObservable {
			return caretSubj.cast(Caret);
		}
		
		public function set caret(w:*):void {
			caretSubj.onNext(w);
		}
		
		private const selectionSubj:ISubject = new ReplaySubject(1);
		
		public function get selection():IObservable {
			return selectionSubj.cast(Selection);
		}
		
		public function set selection(w:*):void {
			selectionSubj.onNext(w);
		}
	}
}