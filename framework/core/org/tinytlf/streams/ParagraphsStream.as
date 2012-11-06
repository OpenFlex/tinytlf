package org.tinytlf.streams
{
	import org.swiftsuspenders.*;
	import org.tinytlf.values.Block;
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.*;
	
	public class ParagraphsStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<Array<Block, Number, IObservable<TextLine>>>> into an IObservable<Paragraph>
		 */
		public function get observable():IObservable {
			return lines.map(mapBlockLife).scan(scanParagraphs);
		}
		
		private function mapBlockLife(life:IObservable):Paragraph {
			const paragraph:Paragraph = new Paragraph(life);
			injector.injectInto(paragraph);
			return paragraph;
		}
		
		private function scanParagraphs(prev:Paragraph, now:Paragraph):Paragraph {
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