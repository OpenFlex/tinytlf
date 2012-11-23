package org.tinytlf.lambdas
{
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextLine;

	/**
	 * @author ptaylor
	 */
	public function getInvalidLines(block:TextBlock):Array {
		// Create an array of the existing still-valid lines.
		const lines:Array = [];
		var line:TextLine = block.firstInvalidLine;
		while(line) {
			lines.push(line);
			line = line.nextLine;
		}
		return lines;
	}	
}