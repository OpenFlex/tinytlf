package org.tinytlf.enum
{
	public class TextBlockProgression
	{
		public static const TTB:String = 'topToBottom';
		public static const LTR:String = 'leftToRight';
		public static const RTL:String = 'rightToLeft';
		
		private static const conversionMap:Object = {
			leftToRight: 'leftToRight',
			rightToLeft: 'rightToLeft',
			topToBottom: 'topToBottom',
			lefttoright: 'leftToRight',
			righttoleft: 'rightToLeft',
			toptobottom: 'topToBottom',
			'left-to-right': 'leftToRight',
			'right-to-left': 'rightToLeft',
			'top-to-bottom': 'topToBottom',
			ltr: 'leftToRight', 
			rtl: 'rightToLeft', 
			ttb: 'topToBottom',
			lr: 'leftToRight',
			rl: 'rightToLeft',
			tb: 'topToBottom'
		};
		
		public static function convert(value:String):String
		{
			if(isValid(value))
				return conversionMap[value];
			
			throwArgumentError(value);
			return ''
		}
		
		public static function isValid(value:String):Boolean
		{
			return value in conversionMap;
		}
		
		public static function throwArgumentError(value:String):void
		{
			throw new ArgumentError('TextBlockProgression ' + value + ' is invalid.');
		}
	}
}