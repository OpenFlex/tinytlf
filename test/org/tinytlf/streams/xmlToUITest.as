package org.tinytlf.streams
{
	import flash.display.DisplayObject;
	
	import org.flexunit.assertThat;
	import org.flexunit.asserts.assertNotNull;
	import org.tinytlf.classes.Container;

	public class xmlToUITest
	{		
		[Test(async)]
		public function fxnReturnsContainerFromOnlyRootNode():void {
			xmlToUI(<body/>).subscribe(function(obj:DisplayObject):void {
				assertThat(obj is Container);
			});
		}
		
		[Test(async)]
		public function fxnReturnsContainerThatHasChildrenFromTree():void {
			xmlToUI(<body><p/></body>).subscribe(function(obj:DisplayObject):void {
				assertThat(obj is Container);
				assertThat(Container(obj).numChildren == 1);
			});
		}
		
		[Test(async)]
		public function fxnReturnsContainerThatHasContainerChildrenFromTree():void {
			xmlToUI(<body><div><p/></div></body>).subscribe(function(obj:DisplayObject):void {
				assertThat(obj is Container);
				assertThat(Container(obj).numChildren == 1);
				
				const child:Container = Container(obj).getChildAt(0) as Container;
				assertNotNull(child);
				assertThat(child.numChildren == 1);
			});
		}
	}
}