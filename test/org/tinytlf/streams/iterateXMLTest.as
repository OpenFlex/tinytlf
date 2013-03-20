package org.tinytlf.streams
{
	import asx.fn.I;
	
	import org.flexunit.asserts.assertTrue;
	import org.flexunit.async.Async;
	import org.tinytlf.actors.elementsOfXML;

	public class iterateXMLTest
	{
		[Test(async)]
		public function fxnIteratesCorrectNumberOfChildren():void {
			const asyncHandler:Function = Async.asyncHandler(this, I, 500);
			
			elementsOfXML(<body><div/><div/><div/></body>).
				count().
				subscribe(function(total:Number):void {
					assertTrue(total == 3);
					asyncHandler();
				});
		}
	}
}