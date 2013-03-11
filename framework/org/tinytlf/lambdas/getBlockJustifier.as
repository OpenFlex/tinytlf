package org.tinytlf.lambdas
{
	import flash.text.engine.LineJustification;
	import flash.text.engine.TextJustifier;
	
	import org.tinytlf.enum.TextAlign;
	import org.tinytlf.types.Styleable;

	/**
	 * @author ptaylor
	 */
	public function getBlockJustifier(styles:Styleable):TextJustifier {
		
		const justification:String = styles.getStyle('textAlign') == TextAlign.JUSTIFY ?
			LineJustification.ALL_BUT_LAST : LineJustification.UNJUSTIFIED;
		
		const justifier:TextJustifier = TextJustifier.getJustifierForLocale(styles.getStyle('locale') || 'en_us');
		justifier.lineJustification = justification;
		
		styles.applyTo(justifier);
		
		return justifier;
	}
}