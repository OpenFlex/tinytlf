package org.tinytlf.lambdas
{
	import flash.text.engine.*;
	
	import org.tinytlf.pools.*;

	/**
	 * @author ptaylor
	 */
	public function createTextLine(block:TextBlock, line:TextLine, width:Number):TextLine {
		const orphan:TextLine = TextLines.checkOut();
		return orphan ?
			block.recreateTextLine(orphan, line, width, 0.0, true) :
			block.createTextLine(line, width, 0.0, true);
	}
}