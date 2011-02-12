package org.tinytlf.conversion
{
	import flash.text.engine.*;
	
	import org.tinytlf.analytics.ITextEngineAnalytics;
	import org.tinytlf.layout.properties.LayoutProperties;
	import org.tinytlf.model.*;
	import org.tinytlf.model.xml.TagSoup;
	import org.tinytlf.util.*;
	import org.tinytlf.util.fte.TextBlockUtil;
	
	/**
	 * EditableBlockFactory keeps track of TextBlocks with an eye towards an on
	 * the editable model.
	 */
	public class EditableBlockFactory extends TextBlockFactoryBase implements ITextBlockFactory
	{
		override public function getTextBlock(index:int):TextBlock
		{
			if(index >= numBlocks)
				return null;
			
			var a:ITextEngineAnalytics = engine.analytics;
			var block:TextBlock = a.getBlockAt(index);
			
			var node:ITLFNode = root.getChildAt(index);
			
			if(!block)
				block = textBlockGenerator.generate(node, getElementFactory(node.name));
			
			var props:LayoutProperties = TinytlfUtil.getLP(block);
			
			if(props.model != node)
			{
				a.removeBlockAt(index);
				block = textBlockGenerator.generate(node, getElementFactory(node.name));
			}
			
			props.model = node;
			
			return block;
		}
		
		override public function getElementFactory(element:*):IContentElementFactory
		{
			if(!(element in elementAdapterMap))
			{
				var adapter:IContentElementFactory = new TLFNodeElementFactory();
				IContentElementFactory(adapter).engine = engine;
				return adapter;
			}
			
			return super.getElementFactory(element);
		}
		
		override public function get numBlocks():int
		{
			return root.numChildren;
		}
		
		private var root:ITLFNodeParent = new TLFNode();
		
		override public function set data(value:Object):void
		{
			if((value is String) || (value is XML) || (value is XMLList))
			{
				XML.prettyPrinting = false;
				XML.ignoreWhitespace = false;
				
				root = buildNode(TagSoup.toXML(value.toString(), true)) as ITLFNodeParent;
				value = root;
				
				engine.analytics.clear();
			}
			
			super.data = value;
		}
		
		private function buildNode(child:XML):ITLFNode
		{
			var node:TLFNode;
			
			if(child..*.length() > 0)
			{
				node = new TLFNode();
				node.engine = engine;
				node.mergeWith(XMLUtil.buildKeyValueAttributes(child.attributes()));
				
				if(child..*.length() == 1)
				{
					node.addChild(new TLFNode(child.toString()));
					node.getChildAt(node.numChildren - 1).engine = engine;
				}
				else
				{
					for each(var x:XML in child.*)
					{
						node.addChild(buildNode(x));
					}
				}
				
				node.name = child.localName();
			}
			else if(child.nodeKind() == 'text')
			{
				node = new TLFNode(child.toString());
				node.engine = engine;
			}
			
			return node;
		}
	}
}