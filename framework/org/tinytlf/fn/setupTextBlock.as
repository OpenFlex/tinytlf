package org.tinytlf.fn
{
	import flash.text.engine.ContentElement;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextRotation;
	
	import org.tinytlf.observables.Values;

	/**
	 * @author ptaylor
	 */
	public function setupTextBlock(block:TextBlock, content:ContentElement, element:Values):TextBlock
	{
		block.content = content;
		block.lineRotation = element.lineRotation || TextRotation.ROTATE_0;
		block.textJustifier = getBlockJustifier(element);
		
		// TODO: The rest of the setup for block progressions and alignment.
		
		return block;
	}
}