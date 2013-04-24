package org.tinytlf.fn
{
	import flash.text.engine.*;

	/**
	 * @author ptaylor
	 */
	public function getValidLines(block:TextBlock):Array {
		// Create an array of the existing still-valid lines.
		const lines:Array = [];
		const lastValidLine:TextLine = getLineBeforeFirstInvalidLine(block);
		var line:TextLine = block.firstLine;
		while(line && line != lastValidLine) {
			lines.push(line);
			line = line.nextLine;
		}
		return lines;
	}	
}