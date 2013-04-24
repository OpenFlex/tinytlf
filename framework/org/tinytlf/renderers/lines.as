package org.tinytlf.renderers
{
	import asx.fn.I;
	
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextLine;
	
	import org.tinytlf.fn.createTextLine;
	import org.tinytlf.fn.getLineBeforeFirstInvalidLine;
	import org.tinytlf.fn.getValidLines;
	import org.tinytlf.fn.isBlockInvalid;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function lines(width:Number, block:TextBlock):IObservable {
		
		var breakAnother:Boolean = false;
		
		const predicate:Function = function(line:TextLine):Boolean {
			return breakAnother;
		};
		
		const iterate:Function = function(line:TextLine):TextLine {
			
			// gimme me a textline.
			line = createTextLine(block, line, width);
			
			// break another while the block is still invalid.
			breakAnother = isBlockInvalid(block);
			
			return line;
		};
		
		// If the block is invalid, it's possible there's some valid lines.
		// Don't re-render all the lines if we don't have to.
		if(isBlockInvalid(block)) {
			
			// Get valid lines to start from.
			const validLines:Array = getValidLines(block);
			
			// Check in old lines.
			// TextLines.checkIn.apply(null, getInvalidLines(block));
			
			// Start from a line, but can be null.
			const initial:TextLine = getLineBeforeFirstInvalidLine(block);
			
			// Concat the valid and new lines together.
			return Observable.concat([
				Observable.fromArray(validLines),
				Observable.generate(initial || iterate(null), predicate, iterate, I)
			]);
		}
		
		breakAnother = true;
		
		// Render all the lines.
		return Observable.generate(iterate(null), predicate, iterate, I);
	}
}