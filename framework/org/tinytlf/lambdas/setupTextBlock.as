package org.tinytlf.lambdas
{
	import flash.text.engine.ContentElement;
	import flash.text.engine.TextBlock;
	import flash.text.engine.TextRotation;
	
	import org.tinytlf.types.Styleable;

	/**
	 * @author ptaylor
	 */
	public function setupTextBlock(block:TextBlock, content:ContentElement, styles:Styleable):TextBlock
	{
		block.content = content;
		
		block.lineRotation = styles['lineRotation'] || TextRotation.ROTATE_0;
		block.textJustifier = getBlockJustifier(styles);
		
		// TODO: The rest of the setup for block progressions and alignment.
		
		return block;
	}
}