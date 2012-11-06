package org.tinytlf.html
{
	import flash.text.engine.*;
	import flash.utils.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.*;
	import org.tinytlf.interaction.*;
	
	use namespace flash_proxy;
	
	public dynamic class DOMNode extends Styleable implements IDOMNode
	{
		[Inject]
		public var injector:Injector;
		
		[Inject]
		public var css:CSS;
		
		public function DOMNode(node:XML, parent:IDOMNode = null)
		{
			super();
			xml = node;
			_parentNode = parent;
			
			// Apply the node's properties to this object
			for each(var attr:XML in xml.attributes())
				this[attr.localName()] = attr.toString();
			
			inheritanceList = (parentNode ? parentNode.cssInheritanceChain : 'html');
			
			if(nodeName)
				inheritanceList += ' ' + nodeName;
			
			if(hasOwnProperty('class'))
			{
				const classes:String = this['class'];
				classes.split(' ').forEach(function(cls:String, ... args):void {
					inheritanceList += (' .' + cls);
				});
			}
			if(hasOwnProperty('id'))
				inheritanceList += ' #' + this['id'];
		}
		
		[PostConstruct]
		public function initialize():void
		{
			mergeWith(css.lookup(cssInheritanceChain));
			if(hasOwnProperty('style'))
			{
				const c:CSS = new CSS();
				c.inject('inline_style{' + this['style'] + '}');
				mergeWith(c.lookup('inline_style'));
			}
		}
		
		private var xml:XML = <_/>;
		private const nodes:Array = [];
		
		public function getChildAt(index:int):IDOMNode
		{
			if(index in nodes && nodes[index] is IDOMNode)
				return nodes[index];
			
			if(index >= numChildren)
				throw new Error('Invalid index and all that.');
			
			const node:IDOMNode = new DOMNode(xml.children()[index], this);
			injector.injectInto(node);
			nodes[index] = node;
			
			return node;
		}
		
		public function get numChildren():int
		{
			return xml.*.length();
		}
		
		private var _parentNode:IDOMNode;
		public function get parentNode():IDOMNode
		{
			return _parentNode;
		}
		
		private var element:ContentElement;
		public function get content():ContentElement
		{
			return element;
		}
		
		public function set content(ce:ContentElement):void
		{
			element = ce;
		}
		
		private var inheritanceList:String = '';
		public function get cssInheritanceChain():String
		{
			return inheritanceList;
		}
		
		private var eventMirror:*;
		public function set mirror(value:*):void
		{
			eventMirror = value;
			if(value is EventBehavior)
			{
				EventBehavior(value).dom = this;
			}
		}
		
		public function get nodeName():String
		{
			return xml.localName();
		}
		
		public function get length():int
		{
			var len:int = nodeValue.length;
			if(len <= 0 && numChildren)
			{
				for(var i:int = 0, n:int = numChildren; i < n; ++i)
				{
					len += getChildAt(i).length;
				}
			}
			
			return len;
		}
		
		public function get nodeValue():String
		{
			if(xml.nodeKind() == 'text')
				return xml.toString();
			
			return xml..text().toString();
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			if(name.toString() == "*")
			{
				const children:Array = [];
				for(var i:int = 0, n:int = numChildren; i < n; ++i)
				{
					children.push(getChildAt(i));
				}
				return children;
			}
			
			return super.getProperty(name);
		}
		
		override flash_proxy function getDescendants(name:*):*
		{
			const all:Array = [];
			
			for(var i:int = 0, n:int = numChildren; i < n; ++i)
			{
				const child:IDOMNode = getChildAt(i);
				if(child.numChildren)
					all.push.apply(null, child['getDescendants'](name));
				else if(child.nodeName == name || name == '*')
					all.push(child);
			}
			
			return all;
		}
	}
}
