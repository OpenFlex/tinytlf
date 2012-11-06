package org.tinytlf
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.text.engine.*;
	
	import org.swiftsuspenders.*;
	import org.swiftsuspenders.reflection.*;
	import org.tinytlf.box.*;
	import org.tinytlf.box.alignment.*;
	import org.tinytlf.box.paragraph.*;
	import org.tinytlf.box.region.*;
	import org.tinytlf.content.*;
	import org.tinytlf.decoration.*;
	import org.tinytlf.html.*;
	import org.tinytlf.interaction.*;
	import org.tinytlf.layout.*;
	import org.tinytlf.style.*;
	import org.tinytlf.util.*;
	import org.tinytlf.virtualization.*;
	
	public class HTMLTextEngineInjector extends Injector
	{
		public function HTMLTextEngineInjector(engine:ITextEngine)
		{
			super();
			
			map(ITextEngine).toValue(engine);
			
			mapInjections();
			injectMappings();
			
			mapEventMirrors();
			mapCEFs();
			mapTRFs();
		}
		
		protected function mapInjections():void
		{
			map(Injector).toValue(this);
			map(Reflector).toValue(new DescribeTypeJSONReflector());
			
			map(IEventMirrorMap).toValue(new EventMirrorMap());
			map(IContentElementFactoryMap).toValue(new FactoryMap());
			map(IBoxFactoryMap).toValue(new FactoryMap());
			map(ITextDecorationMap).toValue(new FactoryMap());
			map(IElementFormatFactory).toValue(new DOMEFFactory());
			map(ITextDecorator).toValue(new TextDecorator());
			map(CSS).toValue(new CSS());
			map(Observables).toValue(new Observables());
			
			map(Array, '<Sprite>').toValue([new Sprite()]);
			map(Array, '<Box>').toValue([]);
			
			map(MouseSelectionBehavior).toSingleton(MouseSelectionBehavior);
			
			// When someone asks for a vanilla Virtualizer,
			// assume they want the one we use for layout.
			const v:Virtualizer = new Virtualizer();
			map(Virtualizer).toValue(v);
			map(Virtualizer, 'layout').toValue(v);
			
			// Create a virtualizer to store IDOMNodes in.
			// This instance is used to lookup elements by caret index
			// for operations like copying text.
			map(Virtualizer, 'content').toValue(new Virtualizer());
		}
		
		protected function injectMappings():void
		{
			injectInto(getInstance(ITextEngine));
			injectInto(getInstance(IEventMirrorMap));
			injectInto(getInstance(IContentElementFactoryMap));
			injectInto(getInstance(ITextDecorationMap));
			injectInto(getInstance(IBoxFactoryMap));
			injectInto(getInstance(IElementFormatFactory));
			injectInto(getInstance(ITextDecorator));
			injectInto(getInstance(Observables));
			injectInto(getInstance(Virtualizer, 'layout'));
			injectInto(getInstance(Virtualizer, 'content'));
			
			map(IDOMNode).toValue(new DOMNode(<_/>));
			injectInto(getInstance(MouseSelectionBehavior));
			unmap(IDOMNode);
			
			// Start off with at least one TextPane.
			const boxes:Array = getInstance(Array, '<Box>');
			boxes.push(instantiateUnmapped(Region));
		}
		
		protected function mapEventMirrors():void
		{
			const emm:IEventMirrorMap = getInstance(IEventMirrorMap);
			emm.mapFactory('a', AnchorMirror);
		}
		
		protected function mapCEFs():void
		{
			const cefm:IContentElementFactoryMap = getInstance(IContentElementFactoryMap);
			
			cefm.defaultFactory = new ClosureCEF();
			cefm.mapFactory('br', new ClosureCEF(function(dom:IDOMNode):ContentElement {
				return ContentElementUtil.lineBreakAfter(ContentElementUtil.getLineBreakGraphic());
			}));
		}
		
		protected function mapTRFs():void
		{
			const bfm:IBoxFactoryMap = getInstance(IBoxFactoryMap);
			const engine:ITextEngine = getInstance(ITextEngine);
			const injector:Injector = this;
			const cllv:Virtualizer = getInstance(Virtualizer, 'content');
			
			bfm.defaultFactory = new ClosureBoxFactory(injector, function(dom:IDOMNode):Array {
				const paragraph:Paragraph = injector.instantiateUnmapped(Paragraph);
				paragraph.domNode = dom;
				paragraph.width = 0;
				paragraph.percentWidth = 100;
				paragraph.percentHeight = 100;
				
				cllv.add(paragraph, dom.length);
				return [paragraph];
			});
			
			const passThrough:Function = function(dom:IDOMNode):Array {
				const boxes:Array = [];
				for(var i:int = 0, n:int = dom.numChildren; i < n; ++i) {
					const child:IDOMNode = dom.getChildAt(i);
					boxes.push.apply(null, bfm.instantiate(child.nodeName)['create'](child));
				}
				return boxes;
			};
			
			bfm.mapFactory('ol', new ClosureBoxFactory(injector, passThrough));
			bfm.mapFactory('ul', new ClosureBoxFactory(injector, passThrough));
			bfm.mapFactory('center', new ClosureBoxFactory(injector, passThrough));
			
			const injectIntoDOMNode:Function = function(dom:IDOMNode, recurse:Boolean = false):void {
				for(var i:int, n:int = dom.numChildren; i < n; ++i) {
					const child:IDOMNode = dom.getChildAt(i);
					injector.injectInto(child);
					if(recurse)
						injectIntoDOMNode(child, recurse);
				}
			};
			
			const containerBF:IBoxFactory = new ClosureBoxFactory(injector,
				// create
				function(dom:IDOMNode, box:Box):Array {
					box.domNode = dom;
					return [box];
				},
				// parse
				function(box:Box):Array {
					injectIntoDOMNode(box.domNode);
					return [box].concat(new ClosureBoxFactory(injector, passThrough).create(box.domNode));
				},
				// render
				function(box:Box):Array {
					return box.children;
				}
			); 
			
			bfm.mapFactory('body', containerBF);
			bfm.mapFactory('div', containerBF);
			
			bfm.mapFactory('hr', new ClosureBoxFactory(injector, function(dom:IDOMNode, box:Box):Array {
				dom.mergeWith(box);
				box.percentWidth = 100;
				box.percentHeight = 100;
				box.height ||= 1;
				box.paddingLeft ||= 2;
				box.paddingRight ||= 2;
				const s:Sprite = new Sprite();
				s.graphics.beginFill(0x00, 0.1);
				s.graphics.drawRect(0, 0, box.width || 1, box.height || 1);
				s.graphics.endFill();
				box.addChild(s);
				
				cllv.add(box, 1);
				return [box];
			},
			null,
			function(box:Box):void {
				const s:Sprite = box.children[0];
				s.width = box.width - box.paddingLeft - box.paddingRight;
				s.height = box.height;
				s.x = box.x;
				s.y = box.y;
			}));
			
			bfm.mapFactory('br', new ClosureBoxFactory(injector, function(dom:IDOMNode):Array {
				const box:Box = injector.instantiateUnmapped(Box);
				box.mergeWith(dom);
				box.percentWidth = 100;
				box.percentHeight = 100;
				box.height = dom['fontSize'] || dom['height'];
				
				cllv.add(box, 1);
				return [box];
			}));
			
			bfm.mapFactory('img', new ClosureBoxFactory(injector, function(dom:IDOMNode, box:Box):Array {
				box.mergeWith(dom);
				box.width = 0;
				box.height = 0;
				box.percentWidth = 100;
				box.percentHeight = 100;
				const loader:Loader = new Loader();
				loader.load(new URLRequest(dom.getStyle('src')));
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);
					dom.applyTo(loader);
					box.addChild(loader);
					engine.invalidate();
				});
				cllv.add(box, 1);
				return [box];
			}, null, function(box:Box):void {
				const kids:Array = box.children;
				if(kids.length == 0)
					return;
				const loader:Loader = kids[0];
				box.progression.position(box, loader);
				box.width = Math.max(box.width, loader.width);
				box.height = Math.max(box.height, loader.height);
			}));
			
			bfm.mapFactory('table', new ClosureBoxFactory(injector, function(dom:IDOMNode):Array {
				const paragraph:Paragraph = injector.instantiateUnmapped(Paragraph);
				paragraph.domNode = new DOMNode(<body><h2>[Table Here]</h2><br/><h5>(Tables aren't supported yet.)</h5></body>);
				paragraph.width = 0;
				paragraph.percentWidth = 100;
				paragraph.percentHeight = 100;
				paragraph.textAlign = TextAlign.CENTER;
				
				cllv.add(paragraph, dom.length);
				return [paragraph];
			}));
			
//			trfm.mapFactory('table', new ClosureTRF(injector, function(dom:IDOMNode, box:Box):Array {
////				box.domNode = dom;
//				box.mergeWith(dom);
//				box.width = 0;
//				box.height = 0;
//				box.percentWidth = 100;
//				box.percentHeight = 100;
//				const s:Sprite = new Sprite();
//				s.graphics.beginFill(0x00, 0.1);
//				s.graphics.drawRect(0, 0, box.width || 1, box.height || 1);
//				s.graphics.endFill();
//				box.addChild(s);
//				
//				cllv.add(box, dom.contentSize);
//				return [box];
//			},
//			null,
//			function(box:Box):void {
//				box.width ||= 100;
//				box.height ||= 100;
//				
//				const s:Sprite = box.children[0];
//				s.width = box.width;
//				s.height = box.height;
//				s.x = box.x;
//				s.y = box.y;
//			}));
		}
	}
}
