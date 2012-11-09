package org.tinytlf.lambdas
{
	import flash.text.engine.*;

	public function toElementFormat(obj:Object):ElementFormat {
		
		if(!obj) {
			return new ElementFormat();
		}
		
		const fd:FontDescription = new FontDescription();
		
		fd.cffHinting = obj.cffHinting || CFFHinting.HORIZONTAL_STEM;
		fd.fontLookup = obj.fontLookup || FontLookup.EMBEDDED_CFF;
		fd.fontName = obj.fontName || obj.fontFamily || '_sans';
		fd.fontPosture = obj.fontStyle == FontPosture.ITALIC ? FontPosture.ITALIC : FontPosture.NORMAL;
		fd.fontPosture = obj.fontPosture || fd.fontPosture;
		fd.fontWeight = obj.fontWeight || FontWeight.NORMAL;
		fd.renderingMode = obj.renderingMode || RenderingMode.CFF;
		
		const ef:ElementFormat = new ElementFormat(fd);
		ef.alignmentBaseline = obj.alignmentBaseline || TextBaseline.USE_DOMINANT_BASELINE;
		ef.alpha = valueFilter(obj.alpha || '1', 'number');
		ef.baselineShift = valueFilter(obj.baselineShift || '0', 'number');
		ef.breakOpportunity = obj.breakOpportunity || BreakOpportunity.AUTO;
		ef.color = valueFilter(obj.color || '0x00', 'uint');
		ef.digitCase = obj.digitCase || DigitCase.DEFAULT;
		ef.digitWidth = obj.digitWidth || DigitWidth.DEFAULT;
		ef.dominantBaseline = obj.objinantBaseline || TextBaseline.ROMAN;
		ef.fontSize = valueFilter(obj.fontSize || obj.size || '12', 'number') * valueFilter(obj.fontMultiplier || '1', 'number');
		ef.kerning = obj.kerning || Kerning.AUTO;
		ef.ligatureLevel = obj.ligatureLevel || LigatureLevel.COMMON;
		ef.locale = obj.locale || 'en_US';
		ef.textRotation = obj.textRotation || TextRotation.AUTO;
		ef.trackingLeft = valueFilter(obj.trackingLeft || '0', 'number');
		ef.trackingRight = valueFilter(obj.trackingRight || '0', 'number');
		ef.typographicCase = obj.typographicCase || TypographicCase.DEFAULT;
		
		return ef;
	}
}

internal function valueFilter(value:String, type:String):* {
	return conversionMap.hasOwnProperty(type) ? conversionMap[type](value) : value;
}

internal const conversionMap:Object = {
	'number': parseFloat,
	'boolean': Boolean,
	'uint': uint
};
