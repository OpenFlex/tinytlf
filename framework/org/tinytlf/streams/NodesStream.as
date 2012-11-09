package org.tinytlf.streams
{
	import org.swiftsuspenders.*;
	import org.tinytlf.classes.*;
	import org.tinytlf.lambdas.*;
	
	import raix.reactive.*;
	import raix.reactive.subjects.*;

	public class NodesStream implements IStream
	{
		/**
		 * Creates an IObservable<IObservable<XML> for each visible block
		 * node, keyed by each node's @cssInheritanceChain attribute.
		 */
		public function get observable():IObservable {
//			return xmlNodes.
//				groupByUntil(nodeKeySelector, nodeDurationSelector).
//				map(snatchNodeValues).
//				publish().refCount();
			// Update when the height or vScroll updates.
			// TODO: Make this work with horizontal block progressions.
			return height.combineLatest(width, identity).
				combineLatest(vScroll, [].concat).
				switchMany(selectVisibleNodes).
				map(keyToXML).
				groupByUntil(nodeKeySelector, nodeDurationSelector).
				map(snatchNodeValues).
				takeUntil(xmlNodes.count()).
				finallyAction(clearXMLDict).
				publish().refCount();
		}
		
		// Selects only the visible nodes, or all nodes
		// if there aren't visible nodes.
		private function selectVisibleNodes(a:Array):IObservable {
			const v:Number = a.pop();
			const h:Number = a.pop();
			const visibleNodes:Array = virtualizer.slice(v, v + h);
			
			return visibleNodes.length > 0 ?
				Observable.fromArray(visibleNodes).concat(Observable.never()) :
				xmlNodes;
		}
		
		private var xmlDict:Object = {};
		private function keyToXML(val:*):XML {
			const key:String = val is XML ? val.@cssInheritanceChain.toString() : val;
			return val is XML ? xmlDict[key] = val : xmlDict[val];
		}
		
		private function clearXMLDict():void {
			xmlDict = {};
		}
		
		// Keys the node lifetime based on its 'cssInheritanceChain' attribute.
		private function nodeKeySelector(node:XML):String {
			return node.@cssInheritanceChain;
		}
		
		// Emits a value when the node's life is over.
		private function nodeDurationSelector(group:IGroupedObservable):IObservable {
			return Observable.merge([
				nodeScrolledOffScreen(group),
				nodeContentWasDeleted(group).peek(virtualizer.remove)
			]);
		}
		
		private function nodeScrolledOffScreen(group:IGroupedObservable):IObservable {
			return height.combineLatest(width, identity).
				combineLatest(vScroll, [].concat).
				combineLatest(Observable.value(group.key), [].concat).
				filter(filterNodeVisibility);
		}
		
		private function nodeContentWasDeleted(group:IObservable):IObservable {
			return group.filter(filterNodeHasContent);
		}
		
		// Terminate if the node is above or below the current viewport.
		private function filterNodeVisibility(a:Array):Boolean {
			const key:String = a.pop();
			const v:Number = a.pop();
			const h:Number = a.pop();
			
			// If the node is in the virtualizer, check its position on the
			// screen. Terminate if it's above or below the current viewport.
			if(virtualizer.getIndex(key) != -1) {
				const start:int = virtualizer.getStart(key);
				const size:int = virtualizer.getSize(key);
				return (start + size) < v || start > (v + h);
			}
			
			// Otherwise return false, indicating this node isn't done
			// being on the screen yet.
			return false;
		}
		
		private function filterNodeHasContent(node:XML):Boolean {
			return node.toString() == '' && node.text().toString() == '';
		}
		
		private function snatchNodeValues(group:IObservable):IObservable {
			const subj:ISubject = new ReplaySubject(1);
			group.subscribeWith(subj);
			return subj;
		}
		
		[Inject]
		public var virtualizer:Virtualizer;
		
		[Inject(name="width")]
		public var width:IObservable;
		
		[Inject(name="height")]
		public var height:IObservable;
		
		[Inject(name="hScroll")]
		public var hScroll:IObservable;
		
		[Inject(name="vScroll")]
		public var vScroll:IObservable;
		
		[Inject(name="html")]
		public var html:IObservable;
		
		[Inject(name="xml")]
		public var xmlNodes:IObservable;
	}
}