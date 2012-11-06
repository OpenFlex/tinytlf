package org.tinytlf
{
	import flash.display.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.classes.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.streams.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;

	public class TextEngine extends Injector
	{
		public function TextEngine()
		{
			super();
			
			map(Injector).toValue(this);
			map(TextEngine).toValue(this);
			map(CSS).asSingleton();
			map(Virtualizer).asSingleton();
			
			// An Observable stream of inputs.
			map(ISubject, 'html').toValue(htmlSubj);
			map(IObservable, 'html').toValue(html);
			
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
			
			// An Observable stream of Caret infor.
			map(ISubject, 'caret').toValue(caretSubj);
			map(IObservable, 'caret').toValue(caret);
			
			// An Observable stream of block-level XML nodes.
			const xmlNodesSubj:ISubject = new ReplaySubject();
			map(ISubject, 'xml').toValue(xmlNodesSubj);
			map(IObservable, 'xml').toValue(xmlNodesSubj.cast(XML));
			
			hScroll = 0;
			vScroll = 0;
			
			map(Object, 'block').toValue({});
			map(Object, 'inline').toValue({});
			
			const castInner:Function = function(type:Class):Function {
				return function(o:IObservable):IObservable {
					return o.cast(type);
				}
			};
			
			const htmlBlockElementObs:IObservable = IStream(instantiateUnmapped(HTMLBlockElementStream)).observable;
			map(IObservable, 'htmlBlockElements').toValue(htmlBlockElementObs.map(castInner(XML)));
			
			// An Observable stream of block-level XML node lifecycles.
			const nodesObs:IObservable = IStream(instantiateUnmapped(NodesStream)).observable;
			map(IObservable, 'nodes').toValue(nodesObs.map(castInner(XML)));
			
			// An Observable stream of ContentElement lifecycles.
			const contentsObs:IObservable = IStream(instantiateUnmapped(ContentsStream)).observable;
			map(IObservable, 'contents').toValue(contentsObs.map(castInner(Content)));
			
			// An Observable stream of TextBlock lifecycles.
			const blocksObs:IObservable = IStream(instantiateUnmapped(BlocksStream)).observable;
			map(IObservable, 'blocks').toValue(blocksObs.map(castInner(Block)));
			
			// An Observable stream of TextBlock lifecycles.
			const linesObs:IObservable = IStream(instantiateUnmapped(LinesStream)).observable;
			map(IObservable, 'lines').toValue(linesObs.map(castInner(Array)));
			
			// An Observable stream of Paragraph lifecycles.
			const paragraphsObs:IObservable = IStream(instantiateUnmapped(ParagraphsStream)).observable;
			map(IObservable, 'paragraphs').toValue(paragraphsObs.cast(DisplayObject));
			
			htmlBlockElementObs.subscribe(xmlNodesSubj.onNext);
		}
		
		private const htmlSubj:ISubject = new ReplaySubject(1);
		
		public function get html():IObservable {
			return htmlSubj.map(toXML).cast(XML);
		}
		
		public function set html(w:*):void {
			htmlSubj.onNext(w);
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
	}
}