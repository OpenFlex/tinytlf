package org.tinytlf.streams
{
	import flash.text.engine.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;

	public class ContentsStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<XML>> into an IObservable<IObservable<Content>>
		 */
		public function get observable():IObservable {
			// For each node, asynchronously parse it into a ContentElement.
			return nodes.mapMany(mapGroup);
		}
		
		private function mapGroup(group:IObservable):IObservable {
			return group.map(recurse);
		}
		
		private function recurse(node:XML):IObservable {
			const name:String = node.localName();
			const numChildren:int = node.*.length();
			
			if(numChildren == 0) {
				return Observable.value({
					node: node,
					content: parsers.hasOwnProperty(name) ?
						parsers[name](node, []) :
						new TextElement(node.toString(), new ElementFormat())
				});
			}
			
			return iterate(node, numChildren, name);
		}
		
		private function iterate(node:XML, numChildren:int, name:String):IObservable {
			return Observable.generate(0,
					function(i:int):Boolean { return i < numChildren; },
					function(i:int):Boolean { return i + 1; },
					function(i:int):XML { return node.children()[i]; }
//					, Scheduler.greenThread
				).
				map(iterateMapChild).
				concatMany(iterateConcatMany).
				toArray().
				map(function(elements:Array):Object {
					return new Content(
						node, 
						parsers.hasOwnProperty(name) ?
							parsers[name](node, elements) :
							new GroupElement(Vector.<ContentElement>(elements), new ElementFormat())
					);
				});
		}
		
		private function iterateMapChild(child:XML):XML {
			child.@cssInheritanceChain = getInheritanceChain(child);
			return child;
		}
		
		private function iterateConcatMany(node:XML):IObservable {
			return recurse(node).map(function(child:Object):ContentElement {
				return child.content;
			});
		}
		
		[Inject(name="nodes")]
		public var nodes:IObservable;
		
		[Inject(name="inline")]
		public var parsers:Object;
	}
}