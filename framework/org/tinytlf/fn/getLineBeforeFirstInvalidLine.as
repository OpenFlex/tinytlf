package org.tinytlf.fn
{
	import flash.text.engine.*;

	/**
	 * @author ptaylor
	 */
	public function getLineBeforeFirstInvalidLine(block:TextBlock):TextLine
	{
		var line:TextLine = block.firstInvalidLine;
		while(line) {
			if(line.validity == TextLineValidity.VALID)
				break;
			
			line = line.previousLine;
		}
		return line;
	}	
}