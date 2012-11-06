package org.tinytlf.streams
{
	import flash.text.engine.*;
	
	import org.tinytlf.lambdas.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;

	public class LinesStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<Block>> into an IObservable<IObservable<Array<Block, IObservable<TextLine>>>>
		 */
		public function get observable():IObservable {
			return blocks.map(mapBlocks);
		}
		
		private function mapBlocks(blockObs:IObservable):IObservable {
			return blockObs.
				combineLatest(width, [].concat).
				scan(scanBlockAndWidth, [0, 0, 0], true);
		}
		
		private function scanBlockAndWidth(b_w_l:Array, b_w:Array):Array {
			const prevWidth:Number = b_w_l[1];
			const newWidth:Number = b_w.pop();
			const block:Block = b_w.pop();
			
			return [block, newWidth, createLineBreaker(block, prevWidth, newWidth)];
		}
		
		private function createLineBreaker(block:Block, prevWidth:Number, newWidth:Number):IObservable {
			const validLines:Array = getValidLines(block.block);
			
			var breakAnother:Boolean = isBlockInvalid(block.block) || newWidth != prevWidth;
			
			const predicate:Function = function(line:TextLine):Boolean {
				return breakAnother;
			};
			
			const iterate:Function = function(line:TextLine):TextLine {
				line = createTextLine(block.block, line, newWidth);
				breakAnother = isBlockInvalid(block.block);
				return line;
			};
			
			const initial:TextLine = getLineBeforeFirstInvalidLine(block.block) || iterate(null);
			
			return Observable.concat([
					Observable.fromArray(validLines),
					Observable.generate(initial, predicate, iterate, identity)
				]).
				map(function(line:TextLine):Line {
					return new Line(line, block);
				}).
				scan(scanLine);
		}
		
		private function scanLine(prev:Line, now:Line):Line {
			prev.next = now;
			now.prev = prev;
			return now;
		}
		
		[Inject(name="blocks")]
		public var blocks:IObservable;
		
		[Inject(name="width")]
		public var width:IObservable;
	}
}