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
		public const b:Caret;
		
		public function setA(a:Caret):Selection {
			return new Selection(a, b);
		}
		
		public function setB(b:Caret):Selection {
			return new Selection(a, b);
		}
	}
}