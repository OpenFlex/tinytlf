package org.tinytlf.fn
{
	import flash.text.engine.LineJustification;
	import flash.text.engine.TextJustifier;
	
	import org.tinytlf.enum.TextAlign;
	import org.tinytlf.observables.Values;

	/**
	 * @author ptaylor
	 */
	public function getBlockJustifier(element:Values):TextJustifier {
		
		const justification:String = element.textAlign == TextAlign.JUSTIFY ?
			LineJustification.ALL_BUT_LAST :
			LineJustification.UNJUSTIFIED;
		
		const justifier:TextJustifier = TextJustifier.getJustifierForLocale(element.locale || 'en_us');
		justifier.lineJustification = justification;
		
		element.applyTo(justifier);
		
		return justifier;
	}
}