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
			// Update when the height or vScroll updates.
			// TODO: Make this work with horizontal block progressions.
			return height.
				combineLatest(vScroll, [].concat).
				switchMany(selectVisibleNodes).
				groupByUntil(nodeKeySelector, nodeDurationSelector).
				map(snatchNodeValues).
				takeUntil(xmlNodes.ignoreValues());
		}
		
		// Selects only the visible nodes, or all nodes
		// if there aren't visible nodes.
		private function selectVisibleNodes(a:Array):IObservable {
			const v:Number = a.pop();
			const h:Number = a.pop();
			const visibleNodes:Array = virtualizer.slice(v, v + h)
			
			return visibleNodes.length > 0 ?
				Observable.fromArray(visibleNodes).concat(Observable.never()) :
				xmlNodes;
		}
		
		// Keys the node lifetime based on its 'cssInheritanceChain' attribute.
		private function nodeKeySelector(node:XML):String {
			return node.@cssInheritanceChain;
		}
		
		// Emits a value when the node's life is over.
		private function nodeDurationSelector(group:IObservable):IObservable {
			return Observable.merge([
				nodeScrolledOffScreen(group),
				nodeContentWasDeleted(group).peek(virtualizer.remove)
			]);
		}
		
		private function nodeScrolledOffScreen(group:IObservable):IObservable {
			return height.
				combineLatest(vScroll, [].concat).
				combineLatest(group, [].concat).
				filter(filterNodeVisibility);
		}
		
		private function nodeContentWasDeleted(group:IObservable):IObservable {
			return group.filter(filterNodeHasContent);
		}
		
		// Terminate if the node is above or below the current viewport.
		private function filterNodeVisibility(a:Array):Boolean {
			const node:XML = a.pop();
			const v:Number = a.pop();
			const h:Number = a.pop();
			
			// If the node is in the virtualizer, check its position on the
			// screen. Terminate if it's above or below the current viewport.
			if(virtualizer.getIndex(node) != -1) {
				const start:int = virtualizer.getStart(node);
				const size:int = virtualizer.getSize(node);
				return (start + size) < v || (start + size) > (v + h);
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