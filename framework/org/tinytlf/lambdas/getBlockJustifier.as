package org.tinytlf.lambdas
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.constants.*;

	/**
	 * @author ptaylor
	 */
	public function getBlockJustifier(styles:Styleable):TextJustifier {
		const justification:String = styles['textAlign'] == TextAlign.JUSTIFY ?
			LineJustification.ALL_BUT_LAST : LineJustification.UNJUSTIFIED;
		
		const justifier:TextJustifier = TextJustifier.getJustifierForLocale(styles['locale'] || 'en_us');
		justifier.lineJustification = justification;
		
		styles.applyTo(justifier);
		
		return justifier;
	}
}