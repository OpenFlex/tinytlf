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
			return lines.map(mapBlockLife).publish().refCount();
		}
		
		private function mapBlockLife(life:IObservable):IObservable {
			const paragraph:Paragraph = injector.instantiateUnmapped(Paragraph);
			paragraph.life = life;
			return life.map(function(...args):Paragraph { return paragraph; });
		}
		
		[Inject]
		public var injector:Injector;
		
		[Inject(name="lines")]
		public var lines:IObservable;
	}
}