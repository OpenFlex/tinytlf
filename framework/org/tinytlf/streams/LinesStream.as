package org.tinytlf.streams
{
	import flash.text.engine.*;
	
	import org.tinytlf.lambdas.*;
	import org.tinytlf.pools.TextLines;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;

	public class LinesStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<Block>> into an IObservable<IObservable<Array<Block, IObservable<TextLine>>>>
		 */
		public function get observable():IObservable {
			return blocks.map(mapBlocks).publish().refCount();
		}
		
		private function mapBlocks(blockObs:IObservable):IObservable {
			return blockObs.combineLatest(width, concatParams).
				takeUntil(blockObs.count()).
				scan(scanBlockAndWidth, [0, 0, 0], true);
		}
		
		private function scanBlockAndWidth(b_w_l:Array, b_w:Array):Array {
			const prevWidth:Number = b_w_l[1];
			const newWidth:Number = b_w.pop();
			const block:Block = b_w.pop();
			
			return [block, newWidth, createLineBreaker(block, prevWidth, newWidth)];
		}
		
		private function createLineBreaker(block:Block, prevWidth:Number, newWidth:Number):IObservable {
			const blockWidth:Number = newWidth - block['paddingLeft'] - block['paddingRight'];
			
			var breakAnother:Boolean = false;
			const predicate:Function = function(line:TextLine):Boolean {
				return breakAnother;
			};
			
			const iterate:Function = function(line:TextLine):TextLine {
				line = createTextLine(block.block, line, blockWidth);
				breakAnother = isBlockInvalid(block.block);
				return line;
			};
			
			if(isBlockInvalid(block.block)) {
				const validLines:Array = getValidLines(block.block);
				TextLines.checkIn.apply(getInvalidLines(block.block));
				
				const initial:TextLine = getLineBeforeFirstInvalidLine(block.block);
				
				return Observable.concat([
						Observable.fromArray(validLines),
						Observable.generate(initial || iterate(null), predicate, iterate, identity)
					]).
					map(function(line:TextLine):Line {
						return new Line(line, block);
					}).
					scan(scanLine);
			}
			
			breakAnother = true;
			return Observable.
				generate(iterate(null), predicate, iterate, identity).
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