package org.tinytlf.streams
{
	import org.tinytlf.lambdas.*;
	
	import raix.reactive.*;
	
	public class HTMLBlockElementStream implements IStream
	{
		/**
		 * An IObseravble<XML> where each XML node is a lowest-level HTML block
		 * element, e.g. the paragraphs inside this div:
		 * 
		 * <p>
		 * <pre>
		 * 	<div>
		 * 		<p>Paragraph one.</p>
		 * 		<p>Paragraph two.</p>
		 * </div>
		 * </pre>
		 * </p>
		 */
		public function get observable():IObservable {
			return html.
				expand(XMLToBlocks).
				map(expandedXMLToDefaults).
				filter(filterForLowestBlockElements);
		}
		
		private function XMLToBlocks(node:XML):IObservable {
			const name:String = node.localName();
			
			const observable:IObservable = parsers.hasOwnProperty(name) ?
				parsers[name](node) :
				Observable.empty();
			
			return observable.concat(Observable.never());
		}
		
		private function expandedXMLToDefaults(node:XML):XML {
			node.@cssInheritanceChain = getInheritanceChain(node);
			return node;
		}
		
		private function filterForLowestBlockElements(node:XML):Boolean {
			if(parsers.hasOwnProperty(node.localName()) == false) {
				return false;
			}
			for each(var desc:XML in node..*) {
				if(parsers.hasOwnProperty(desc.localName())) {
					return false;
				}
			}
			return true;
		}
		
		private function blockNodeParser(node:XML):IObservable {
			const nodeChildren:Array = [];
			
			for each(var child:XML in node.children()) {
				nodeChildren.push(child);
			}
			
			return Observable.fromArray(nodeChildren);
		}
		
		private function emptyNodeParser(node:XML):IObservable {
			return Observable.empty();
		}
		
		[PostConstruct]
		public function initialize():void
		{
			parsers['body'] = blockNodeParser;
			parsers['div'] = blockNodeParser;
			parsers['p'] = emptyNodeParser;
		}
		
		[Inject(name="block")]
		public var parsers:Object;
		
		[Inject(name="html")]
		public var html:IObservable;
	}
}