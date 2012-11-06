package org.tinytlf.streams
{
	import org.swiftsuspenders.*;
	import org.tinytlf.values.Block;
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.*;
	
	public class ParagraphsStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<Array<Block, Number, IObservable<TextLine>>>>
		 * into an IObservable<IObservable<Paragraph>>.
		 */
		public function get observable():IObservable {
			return lines.map(mapBlockLife);
		}
		
		private function mapBlockLife(life:IObservable):IObservable {
			const paragraph:Paragraph = injector.instantiateUnmapped(Paragraph);
			paragraph.life = life;
			return life.map(function(...args):Paragraph { return paragraph; });
		}
		
		private function scanParagraphs(a:IObservable, b:IObservable):IObservable {
			return a.combineLatest(b, [].concat).map(associateParagraphs);
		}
		
		private function associateParagraphs(a:Array):Paragraph {
			const now:Paragraph = a.pop();
			const prev:Paragraph = a.pop();
			prev.next = now;
			now.prev = prev;
			return now;
		}
		
		[Inject]
		public var injector:Injector;
		
		[Inject(name="lines")]
		public var lines:IObservable;
	}
}