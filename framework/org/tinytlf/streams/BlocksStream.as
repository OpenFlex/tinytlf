package org.tinytlf.streams
{
	import flash.text.engine.TextBlock;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.classes.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.pools.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;

	public class BlocksStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<IObservable<Content>>> into an IObservable<IObservable<Block>>
		 */
		public function get observable():IObservable {
			return contents.map(mapContents);
		}
		
		private function mapContents(contentObs:IObservable):IObservable {
			return contentObs.scan(scanContentToBlock, null, true);
		}
		
		private function scanContentToBlock(block:Block, content:Content):Block {
			const textBlock:TextBlock = setupTextBlock(TextBlocks.checkOut(), content.element, content);
			return new Block(textBlock, content);
		}
		
		[Inject(name="contents")]
		public var contents:IObservable;
	}
}