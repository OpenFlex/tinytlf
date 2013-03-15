package org.tinytlf.types
{
	import raix.reactive.ISubject;
	import raix.reactive.subjects.ReplaySubject;

	public class Renderable
	{
		public function Renderable(node:XML) {
			this['node'] = node;
		}
		
		public const node:XML;
		public const rendered:ISubject = new ReplaySubject(2);
		
		public static function compare(a:Renderable, b:Renderable):Boolean {
			if(!a || !b) return true;
			return a.node.toXMLString() == b.node.toXMLString();
		}
	}
}