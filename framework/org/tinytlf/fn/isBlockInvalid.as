package org.tinytlf.fn
{
	import flash.text.engine.*;

	/**
	 * @author ptaylor
	 */
	public function isBlockInvalid(block:TextBlock):Boolean {
		return block.firstLine == null ||
			block.firstInvalidLine ||
			block.textLineCreationResult != TextLineCreationResult.COMPLETE;
	}
}