package org.tinytlf.streams
{
	import org.tinytlf.values.Paragraph;
	
	import raix.reactive.*;
	
	public class ParagraphsStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<Array<Block, Number, IObservable<TextLine>>>>
		 * into an IObservable<IObservable<Paragraph>>.
		 */
		public function get observable():IObservable {
			return lines.map(mapBlockLife).publish().refCount();
		}
		
		private function mapBlockLife(life:IObservable):IObservable {
			const paragraph:Paragraph = new Paragraph();
			paragraph.life = life;
			return life.
				map(function(...args):Paragraph { return paragraph; }).
				takeUntil(life.count());
		}
		
		[Inject(name="lines")]
		public var lines:IObservable;
	}
}