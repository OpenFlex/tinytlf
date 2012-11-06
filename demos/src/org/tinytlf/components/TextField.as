package org.tinytlf.components
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.*;
	import org.tinytlf.box.*;
	import org.tinytlf.box.progression.*;
	import org.tinytlf.html.*;
	import org.tinytlf.interaction.*;
	import org.tinytlf.layout.*;
	import org.tinytlf.util.*;
	import org.tinytlf.virtualization.*;
	
	public class TextField extends ComponentBase
	{
		public function TextField(editable:Boolean = false)
		{
			super();
			
			this.editable = editable;
		}
		
		private var _css:String = '';
		private var proposedCSS:String = '';
		public function get css():String
		{
			return _css;
		}
		
		public function set css(value:String):void
		{
			if(value == _css)
				return;
			
			proposedCSS = value;
			invalidate();
		}
		
		private var _editable:Boolean = false;
		public function get editable():Boolean
		{
			return _editable;
		}
		
		public function set editable(value:Boolean):void
		{
			if(value == _editable)
				return;
			
			_editable = value;
			injector = editable ?
				new EditableTextEngineInjector(new TextEngine()) :
				new HTMLTextEngineInjector(new TextEngine());
			
			invalidate();
		}
		
		private var _html:XML = <_/>;
		private var proposedHTML:* = '';
		
		public function get html():*
		{
			return _html;
		}
		
		public function set html(value:*):void
		{
			if(!(value is XML || value is String))
			{
				throw new ArgumentError('HTML must be either XML or a String.');
			}
			
			proposedHTML = value;
			invalidate();
		}
		
		private var _injector:Injector;
		private var injectorChanged:Boolean = false;
		
		public function get injector():Injector
		{
			return _injector;
		}
		
		public function set injector(value:Injector):void
		{
			if(value == injector || !value)
				return;
			
			_injector = value;
			injectorChanged = true;
			invalidate();
		}
		
		private var invalidated:Boolean = false;
		public function invalidate():void
		{
			if(invalidated)
				return;
			
			invalidated = true;
			addEventListener(Event.ENTER_FRAME, function(e:Event):void {
				removeEventListener(e.type, arguments.callee);
				validate();
				invalidated = false;
			});
		}
		
		protected function validateInjector():void
		{
			while(numChildren)
			{
				removeChildAt(0);
			}
			
			const engine:ITextEngine = injector.getInstance(ITextEngine);
			const obs:Observables = injector.getInstance(Observables);
			obs.mouseWheel(this).subscribe(function(me:MouseEvent):void {
				engine.scroll = new Point(engine.scroll.x, engine.scroll.y - me.delta);
			});
		}
		
		protected function validateCSS(css:String):void
		{
			const engine:ITextEngine = injector.getInstance(ITextEngine);
			const c:CSS = injector.getInstance(CSS);
			c.clearStyles();
			c.inject(css);
			engine.scroll = new Point();
		}
		
		protected function validateHTML(html:XML):void
		{
			const cllv:Virtualizer = injector.getInstance(Virtualizer, 'content');
			cllv.clear();
			
			const engine:ITextEngine = injector.getInstance(ITextEngine);
			const c:CSS = injector.getInstance(CSS);
			c.inject(html..style.text().toString());
			engine.scroll = new Point();
		}
		
		protected function validate():void
		{
			if(injectorChanged || proposedCSS || proposedHTML)
			{
				const engine:ITextEngine = injector.getInstance(ITextEngine);
				const c:CSS = injector.getInstance(CSS);
				
				if(injectorChanged)
				{
					validateInjector();
					injectorChanged = false;
				}
				if(proposedCSS)
				{
					validateCSS(_css = proposedCSS);
					proposedCSS = '';
				}
				if(proposedHTML)
				{
					validateHTML(
						_html = createHTML_XML(
							(proposedHTML is String ?
								TagSoup.toXML(proposedHTML) : 
								proposedHTML)
							as XML)
					);
					proposedHTML = null;
				}
				
				const g:Graphics = graphics;
				g.clear();
				g.beginFill(0xFFFFFF, 1);
				g.lineStyle(1, 0xCCCCCC);
				g.drawRect(1, 1, width - 1, height - 1);
				
				const boxes:Array = injector.getInstance(Array, '<Box>');
				const box:Box = boxes[0];
				const dom:IDOMNode = box.domNode = new DOMNode(html);
				box.blockProgression = TextBlockProgression.convert(dom.getStyle('textDirection') || TextBlockProgression.TTB);
				box.width = width - 2;
				box.height = height - 2;
				
				const containers:Array = injector.getInstance(Array, '<Sprite>');
				addChild(containers[0]);
				containers[0].x = 1;
				containers[0].y = 2;
				
				engine.invalidate();
			}
		}
		
		protected function createHTML_XML(from:XML):XML
		{
			return from.localName() == 'body' ?
				from :
				(from..body[0] || <body>{from}</body>)
		}
	}
}
