package org.tinytlf.types
{
	import raix.reactive.ISubject;
	import raix.reactive.Subject;

	public class Renderable
	{
		public function Renderable(node:XML) {
			this['node'] = node;
		}
		
		public const node:XML;
		public const rendered:ISubject = new Subject();
		
		public static function compare(a:Renderable, b:Renderable):Boolean {
			if(!a || !b) return true;
			return a.node.toXMLString() == b.node.toXMLString();
		}
	}
}