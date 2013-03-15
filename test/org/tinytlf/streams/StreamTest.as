package org.tinytlf.streams
{
	import flash.geom.Rectangle;
	
	import org.tinytlf.lambdas.toInheritanceChain;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.Renderable;
	
	import raix.reactive.ISubject;
	import raix.reactive.scheduling.Scheduler;
	import raix.reactive.subjects.ReplaySubject;
	
	import trxcllnt.ds.RTree;

	public class StreamTest
	{
		public function StreamTest()
		{
			setUp();
		}
		
		protected const css:CSS = new CSS();
		protected const cache:RTree = new RTree();
		protected const dimensions:Rectangle = new Rectangle(0, 0, 100, 100);
		
		protected const styles:ISubject = new ReplaySubject(1);
		protected const viewport:ISubject = new ReplaySubject(1);
		
		public function setUp():void
		{
			styles.onNext(css);
			viewport.onNext(dimensions);
		}
		
		protected function cacheNodeKeys(tree:RTree):Function {
			var i:int = 0;
			return function(renderable:Renderable):void {
				const key:String = toInheritanceChain(renderable.node);
				
				if(tree.find(key) == null)
					tree.insert(key, new Rectangle(0, i++ * 75, 75, 75));
				
				Scheduler.immediate.schedule(function():void{
					renderable.rendered.onCompleted();
				}, 10);
			}
		}
	}
}