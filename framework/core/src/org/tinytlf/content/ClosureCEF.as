package org.tinytlf.content
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.engine.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.decoration.*;
	import org.tinytlf.html.*;
	import org.tinytlf.interaction.*;
	import org.tinytlf.style.*;
	
	/**
	 * <p>
	 * ClosureCEF is a ContentElement Factory that calls a closure to create
	 * ContentElements.
	 * </p>
	 *
	 * <p>
	 * The closure's method signature should accept an IDOMNode argument and
	 * return a ContentElement instance:
	 * </p>
	 *
	 * <p>
	 * <code>function(node:IDOMNode):ContentElement{}</code>
	 * </p>
	 */
	public class ClosureCEF implements IContentElementFactory
	{
		[Inject]
		public var cefm:IContentElementFactoryMap;
		[Inject]
		public var decorator:ITextDecorator;
		[Inject]
		public var emm:IEventMirrorMap;
		[Inject]
		public var eff:IElementFormatFactory;
		[Inject]
		public var injector:Injector;
		
		public function ClosureCEF(closure:Function = null)
		{
			createFunc = closure || function(dom:IDOMNode):ContentElement {
				var element:ContentElement;
				
				if(dom.numChildren)
				{
					const elements:Vector.<ContentElement> = new <ContentElement>[];
					for(var i:int = 0, n:int = dom.numChildren; i < n; ++i)
					{
						const child:IDOMNode = dom.getChildAt(i);
						elements.push(cefm.instantiate(child.nodeName).create(child));
					}
					element = new GroupElement(elements, eff.getElementFormat(dom), new EventDispatcher());
				}
				else if(dom.nodeValue)
				{
					element = new TextElement(dom.nodeValue, eff.getElementFormat(dom));
				}
				else
				{
					element = new GraphicElement(new Shape(), 0, 0, eff.getElementFormat(dom));
				}
				
				// Associate these objects with each other.
				dom.content = element;
				element.userData = dom;
				dom.mirror = emm.instantiate(dom);
				
				if(!(element is GroupElement))
				{
					//Do any decorations for this element.
					decorator.decorate(element, dom, dom['layer'], dom['foreground']);
				}
				
				return element;
			};
		}
		
		private var createFunc:Function;
		
		public function create(dom:IDOMNode):ContentElement
		{
			return createFunc(dom);
		}
	}
}
