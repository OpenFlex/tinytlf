package org.tinytlf.lambdas
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;

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