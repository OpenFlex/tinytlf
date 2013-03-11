package org.tinytlf.lambdas
{
	import org.flexunit.asserts.assertTrue;
	import org.tinytlf.procedures.applyNodeInheritance;

	public class deriveNodeInheritanceTests
	{
		private const xml:XML =
<body id="container" class="first second">
	<div id="section" class="third fourth">
		<p id="content" class="body-text">Lorem ipsum.</p>
	</div>
</body>;

		[Test]
		public function testDerive():void {
			const body:String = deriveNodeInheritance(xml);
			const div:String = deriveNodeInheritance(xml.div[0]);
			const p:String = deriveNodeInheritance(xml.div[0].p[0]);
			
			assertTrue(body == 'body#container .first .second');
			assertTrue(div == 'div#section:0 .third .fourth');
			assertTrue(p == 'p#content:0 .body-text');
		}
		
		[Test]
		public function testApply():void {
			const body:String = applyNodeInheritance(xml).@cssInheritanceChain;
			const div:String = applyNodeInheritance(xml.div[0]).@cssInheritanceChain;
			const p:String = applyNodeInheritance(xml.div[0].p[0]).@cssInheritanceChain;
			
			assertTrue(body == 'body#container .first .second');
			assertTrue(div == 'body#container .first .second div#section:0 .third .fourth');
			assertTrue(p == 'body#container .first .second div#section:0 .third .fourth p#content:0 .body-text');
		}
	}
}