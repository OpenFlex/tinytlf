package org.tinytlf.streams
{
	import org.tinytlf.classes.*;
	import org.tinytlf.fn.identity;
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
			// TODO: Make this work with horizontal block progressions.
			
			// Do stuff when any of these 4 properties change
			return height.
				combineLatest(vScroll, concatParams).
				combineLatest(width, identity).
				// Mutate the values into an array of visible XML node keys
				map(mapVisibleNodeKeys).
				
				// But only actually do anything if the list is different than last time.
				distinctUntilChanged().
				
				// If there was a previous subscription, cancel it. Turn the
				// Array of visible nodes into an Observable sequence...
				switchMany(selectVisibleNodes).
				
				// ... that we never allow to complete.
				concat(Observable.never()).
				
				// Group the XML nodes by their @cssInheritanceChain value.
				groupByUntil(nodeKeySelector, nodeDurationSelector).
				
				// Immediately subscribe to each IGroupedObservable with a
				// ReplaySubject, otherwise we'll lose this value forever?
				map(snatchNodeValues).
				
				// Take until the xmlNodes subject completes.
				takeUntil(xmlNodes.count()).
				
				// Upon completion, clear out the key to XML node cache.
				finallyAction(clearXMLDict).
				
				// Export this Observable for multiple subscriptions.
				publish().refCount();
		}
		
		private function mapVisibleNodeKeys(a:Array):Array {
			return virtualizer.slice(a[1], a[1] + a[0]);
		}
		
		// Selects only the visible nodes, or all nodes
		// if there aren't visible nodes.
		private function selectVisibleNodes(keys:Array):IObservable {
			return keys.length > 0 ? 
				// Map the keys to their XML counterparts.
				toObservable(keys).map(keyToXML) :
				xmlNodes.peek(cacheXMLNode)
		}
		
		private var xmlDict:Object = {};
		private function keyToXML(key:String):XML {
			return xmlDict[key];
		}
		
		private function cacheXMLNode(node:XML):void {
			const key:String = node.@cssInheritanceChain.toString();
			xmlDict[key] = node;
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
				combineLatest(vScroll, concatParams).
				combineLatest(Observable.value(group.key), concatParams).
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
		
		[Inject(name="css")]
		public var css:IObservable;
		
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