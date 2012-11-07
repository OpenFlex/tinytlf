package org.tinytlf.values
{
	public class Selection
	{
		public function Selection(a:Caret, b:Caret)
		{
			this['a'] = a;
			this['b'] = b;
		}
		
		public const a:Caret;
		public const b:Caret
	}
}