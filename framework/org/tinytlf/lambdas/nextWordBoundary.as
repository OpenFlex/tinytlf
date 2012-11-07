package org.tinytlf.lambdas
{
	import flash.text.engine.TextLine;

	/**
	 * Finds the next/prev word boundary specified by the direction and the
	 * boundaryPattern. If no boundary pattern is specified, the default
	 * is used, which matches non-word characters or graphic characters.
	 * 
	 * @author ptaylor
	 */
	public function nextWordBoundary(line:TextLine, atomIndex:int, left:Boolean = true, boundaryPattern:RegExp = null):int {
		if(!boundaryPattern)
			boundaryPattern = defaultWordBoundaryPattern;
		
		if(atomIndex >= line.atomCount)
			atomIndex = line.atomCount - 1;
		else if(atomIndex < 0)
			atomIndex = 0;
		
		const rawText:String = line.textBlock.content.rawText;
		var adjustedIndex:int = line.getAtomTextBlockBeginIndex(atomIndex);
		
		// If the index is already at a word boundary,
		// move to find the next word boundary.
		while(nonWordPattern.test(rawText.charAt(adjustedIndex)))
		{
			adjustedIndex += left ? -1 : 1;
			atomIndex += left ? -1 : 1;
		}
		
		const text:String = left ?
			rawText.slice(0, adjustedIndex).split("").reverse().join("") :
			rawText.slice(adjustedIndex, rawText.length);
		
		const match:Array = boundaryPattern.exec(text);
		if(match) {
			const str:String = String(match[0]);
			atomIndex += nonWordPattern.test(str) ? 0 : str.length * (left ? -1 : 1);
		}
		
		return Math.max(atomIndex, 0);
	}
}

internal const defaultWordBoundaryPattern:RegExp = /\W+|\b[^\W﷯]*/;
internal const nonWordPattern:RegExp = /\W/;