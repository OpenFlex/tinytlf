package org.tinytlf.types
{
	import asx.array.toArray;
	
	import org.tinytlf.lambdas.toStyleable;

	public class DOMNode extends Styleable
	{
		public function DOMNode(node:XML, root:CSS = null)
		{
			super();
			
			if(node) update(node, root);
		}
		
		public function update(node:XML, root:CSS = null):DOMNode {
			_node = node;
			
			const e:XMLList = node.elements();
			const c:XMLList = node.children();
			
			_elements.length = 0;
			_children.length = 0;
			
			_elements.push.apply(_elements, toArray(e));
			_children.push.apply(_children, toArray(c));
			_index = node.childIndex();
			_name = node.localName();
			_value = node.toString();
			
			return mergeWith(_styles = toStyleable(node, root)) as DOMNode;
		}
		
		private const _children:Array = [];
		public function get children():Array {
			return _children.concat();
		}
		
		private const _elements:Array = [];
		public function get elements():Array {
			return _elements.concat();
		}
		
		private var _index:int = -1;
		public function get index():int {
			return _index;
		}
		
		private var _name:String = '';
		public function get name():String {
			return _name;
		}
		
		private var _node:XML = <_/>;
		public function get node():XML {
			return _node;
		}
		
		private var _styles:Styleable;
		public function get styles():Styleable {
			return _styles;
		}
		
		private var _value:String = '';
		public function get value():String {
			return _value;
		}
	}
}