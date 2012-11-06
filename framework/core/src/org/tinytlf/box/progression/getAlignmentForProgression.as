package org.tinytlf.box.progression
{
	import org.tinytlf.layout.*;
	import org.tinytlf.box.alignment.*;
	
	public function getAlignmentForProgression(textAlign:String, progression:String):IAlignment
	{
		if(!TextAlign.isValid(textAlign))
			TextAlign.throwArgumentError(progression);
		if(!TextBlockProgression.isValid(progression))
			TextBlockProgression.throwArgumentError(progression);
		
		return AlignmentCache.progressionAlignmentMapping[progression][textAlign];
	}
}

import org.tinytlf.box.alignment.*;
internal class AlignmentCache
{
	private static const vLeft:LeftAlignment = new LeftAlignment();
	private static const vRight:RightAlignment = new RightAlignment();
	private static const vCenter:CenterAlignment = new CenterAlignment();
	private static const hLeft:TopAlignment = new TopAlignment();
	private static const hRight:BottomAlignment = new BottomAlignment();
	private static const hCenter:MiddleAlignment = new MiddleAlignment();
	
	private static const hAlignments:Object = {
			justify: hLeft,
			left: hLeft,
			center: hCenter,
			right: hRight
		};
	private static const vAlignments:Object = {
			justify: vLeft,
			left: vLeft,
			center: vCenter,
			right: vRight
		};
	public static const progressionAlignmentMapping:Object = {
			topToBottom: vAlignments,
			leftToRight: hAlignments,
			rightToLeft: hAlignments
		};
}
