package org.tinytlf.streams
{
	import flash.text.engine.*;
	
	import org.tinytlf.classes.*;
	import org.tinytlf.lambdas.*;
	import org.tinytlf.values.*;
	
	import raix.reactive.*;

	public class ContentsStream implements IStream
	{
		/**
		 * Mutates an IObservable<IObservable<XML>> into an IObservable<IObservable<Content>>
		 */
		public function get observable():IObservable {
			// parse each node into a ContentElement
			return nodes.map(mapGroup).publish().refCount();
		}
		
		private function mapGroup(group:IObservable/*<XML>*/):IObservable/*<Content>*/ {
			return group.combineLatest(css, concatParams).
				map(recurse).
				takeUntil(group.count());
		}
		
		private function recurse(a:Array):Content {
			
			const css:CSS = a.pop();
			const node:XML = a.pop();
			const styles:Styleable = a.pop() || toStyleable(node, css);
			
			const name:String = node.localName();
			const numChildren:int = node.*.length();
			
			if(numChildren == 0) {
				return new Content(
					node,
					(parsers.hasOwnProperty(name) ?
						parsers[name](node, []) :
						new TextElement(node.toString(), toElementFormat(styles))),
					styles
				);
			}
			
			const elements:Array = [];
			for(var i:int = -1; ++i < numChildren;) {
				const child:XML = node.children()[i];
				child.@cssInheritanceChain = getInheritanceChain(child);
				elements[i] = recurse([styles, child, css]).element;
			}
			
			return new Content(
				node, 
				(parsers.hasOwnProperty(name) ?
					parsers[name](node, elements) :
					new GroupElement(Vector.<ContentElement>(elements), toElementFormat(styles))
				),
				styles
			);
		}
		
		[Inject(name="nodes")]
		public var nodes:IObservable/*<IObservable<XML>>*/;
		
		[Inject(name="inline")]
		public var parsers:Object;
		
		[Inject(name="css")]
		public var css:IObservable;
	}
}