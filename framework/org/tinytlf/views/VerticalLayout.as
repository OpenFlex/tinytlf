package org.tinytlf.views
{
	import flash.display.DisplayObjectContainer;

	public class VerticalLayout
	{
		public function VerticalLayout(target:DisplayObjectContainer)
		{
			super();
			this['target'] = target;
		}
		
		private const target:DisplayObjectContainer;
		
		public function measure():void {
		}
		
		public function updateDisplayList(w:Number, h:Number):void {
		}
	}
}