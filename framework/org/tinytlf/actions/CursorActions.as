package org.tinytlf.actions
{
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import org.tinytlf.TextEngine;
	import org.tinytlf.TextField;
	import org.tinytlf.events.mouse.out;
	import org.tinytlf.events.mouse.over;

	public class CursorActions
	{
		public function CursorActions(engine:TextEngine, field:TextField)
		{
			engine.subscriptions.add(
				over(field).subscribe(onNextOver)
			);
			engine.subscriptions.add(
				out(field).subscribe(onNextOut)
			);
		}
			
		private function onNextOver(...args):void {
			Mouse.cursor = MouseCursor.IBEAM;
		}
		
		private function onNextOut(...args):void {
			Mouse.cursor = MouseCursor.AUTO;
		}
	}
}