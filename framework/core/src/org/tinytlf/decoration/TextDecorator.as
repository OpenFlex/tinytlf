/*
 * Copyright (c) 2010 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package org.tinytlf.decoration
{
	import org.swiftsuspenders.*;
	import org.swiftsuspenders.reflection.*;
	import org.tinytlf.*;
	
	////
	//	This renders every decoration again every time the decorations are 
	//	invalidated. Isn't there a way to know which decorations changed and
	//	only clear/render those? Without creating separate Shapes/Sprites per
	//	decoration.
	//	
	//	09/05/2010: did some testing tonight, seems this isn't as big a deal (yet)
	//	as I thought it could be. Will keep my eye on the situation.
	////
	
	/**
	 * The default decorator in tinytlf.
	 *
	 * @see org.tinytlf.decoration.ITextDecoration
	 */
	public class TextDecorator implements ITextDecorator
	{
		public static const CARET_LAYER:int = 1;
		public static const SELECTION_LAYER:int = 2;
		
		[Inject]
		public var map:ITextDecorationMap;
		
		[Inject]
		public var engine:ITextEngine;
		
		[Inject]
		public var reflector:Reflector;
		
		public function decorate(element:*, styleObject:Object, layer:int = 3, foreground:Boolean = false):void
		{
			const styleProp:String = String(styleObject);
			var prop:String;
			
			//  Early return optimizations not to loop or invalidate
			//  if there are no decorations in the styleObject.
			if(styleObject is String && !map.hasMapping(styleProp))
			{
				return;
			}
			else
			{
				var hasOne:Boolean = false;
				for(prop in styleObject)
					if(hasOne = map.hasMapping(prop))
						break;
				
				if(hasOne == false)
					return;
			}
			
			const el:Element = getElement(element);
			
			if(styleObject is String)
			{
				el.addDecoration(new Decoration(map.instantiate(styleProp), layer));
			}
			else
			{
				var decoration:ITextDecoration;
				var dec:Decoration;
				var styleValue:*;
				
				for(prop in styleObject)
				{
					styleValue = styleObject[prop];
					
					// You can de-apply a decoration by passing in
					// {decoration:false} or {decoration:null}
					if(styleValue === false || styleValue === 'false' || styleValue == null)
					{
						undecorate(element, prop);
					}
					else if(map.hasMapping(prop))
					{
						// If we've already created a decoration for this
						// property and element, update its properties.
						if((dec = el.getDecoration(reflector.getClass(map.instantiate(styleProp)))) != null)
						{
							decoration = dec.decoration;
							decoration.mergeWith(styleObject);
							continue;
						}
						
						decoration = map.instantiate(styleProp);
						decoration.foreground = foreground;
						decoration.mergeWith(styleObject);
						el.addDecoration(new Decoration(decoration, layer));
					}
				}
			}
			
			engine.invalidateDecorations();
		}
		
		public function undecorate(element:* = null, decorationProp:String = null):void
		{
			if(element === null && decorationProp === null)
				return;
			
			var el:Element;
			var dec:Decoration;
			
			if(element)
			{
				el = getElement(element);
				
				if(!el)
					return;
				
				if(decorationProp)
				{
					if(!map.hasMapping(decorationProp))
						return;
					
					dec = el.getDecoration(reflector.getClass(map.instantiate(decorationProp)));
					while(dec)
					{
						el.removeDecoration(dec);
						dec.destroy();
						dec = el.getDecoration(reflector.getClass(map.instantiate(decorationProp)));
					}
				}
				else
				{
					const decorations:Vector.<Decoration> = el.decorations.concat();
					for each(dec in decorations)
					{
						el.removeDecoration(dec);
						dec.destroy();
					}
				}
				
				cleanupElement(el);
			}
			else
			{
				if(!map.hasMapping(decorationProp))
					return;
				
				const type:Class = reflector.getClass(map.instantiate(decorationProp));
				const ements:Vector.<Element> = elements.concat();
				
				for each(el in ements)
				{
					dec = el.getDecoration(type);
					if(dec)
					{
						el.removeDecoration(dec);
						dec.destroy();
						cleanupElement(el);
					}
				}
			}
			
			engine.invalidateDecorations();
		}
		
		private const elements:Vector.<Element> = new <Element>[];
		
		public function render():void
		{
			elements.forEach(function(el:Element, ... args):void{
				
				// Sort by layer order, so we render decorations
				// on the lowest layer first.
				el.decorations.sort(function(d1:Decoration, d2:Decoration):int{
					return d1.layer - d2.layer;
				});
				
				el.decorations.forEach(function(dec:Decoration, ... args):void{
					dec.draw(dec.setup(el.element));
				});
			});
		}
		
		public function removeAll():void
		{
			elements.forEach(function(el:Element, ... args):void{
				el.decorations.forEach(function(dec:Decoration, ... args):void{
					el.removeDecoration(dec);
					dec.destroy();
				});
			});
			
			elements.length = 0;
		}
		
		protected function getElement(element:*):Element
		{
			const filter:Vector.<Element> = elements.filter(function(e:Element, ... args):Boolean{
				return e.element === element;
			});
			
			if(filter.length)
				return filter[0];
			
			const el:Element = new Element(element);
			elements.push(el);
			return el;
		}
		
		protected function cleanupElement(el:Element):void
		{
			if(el.decorations.length > 0)
				return;
			
			elements.splice(elements.indexOf(el), 1);
			el.decorations = null;
			el.element = null;
		}
	}
}

import flash.events.EventDispatcher;
import flash.geom.Rectangle;
import flash.text.engine.ContentElement;

import org.tinytlf.decoration.ITextDecoration;

internal class Element
{
	public function Element(e:*)
	{
		this.element = e;
		
		const ce:ContentElement = e as ContentElement;
		
		// Give the ContentElement an EventMirror so the FTE will create a
		// TextLineMirrorRegion for the ContentElement.
		if(ce && ce.eventMirror == null)
			ce.eventMirror = new EventDispatcher();
	}
	
	public var element:*;
	public var decorations:Vector.<Decoration> = new Vector.<Decoration>();
	
	public function getDecoration(decorationType:Class):Decoration
	{
		const filter:Vector.<Decoration> = decorations.filter(function(d:Decoration, ... args):Boolean{
			return (d.decoration is decorationType);
		});
		
		return filter.length ? filter[0] : null;
	}
	
	public function addDecoration(decoration:Decoration):void
	{
		if(decorations.indexOf(decoration) == -1)
			decorations.push(decoration);
	}
	
	public function removeDecoration(decoration:Decoration):void
	{
		const i:int = decorations.indexOf(decoration);
		if(i != -1)
			decorations.splice(i, 1);
	}
}

internal class Decoration
{
	public function Decoration(decoration:ITextDecoration, layer:int = 3)
	{
		this.decoration = decoration;
		this.layer = layer;
	}
	
	public function destroy():void
	{
		decoration.destroy();
		decoration = null;
	}
	
	public function setup(... args):Vector.<Rectangle>
	{
		return decoration.setup.apply(null, [layer].concat(args));
	}
	
	public function draw(bounds:Vector.<Rectangle>):void
	{
		decoration.draw(bounds);
	}
	
	public var layer:int = 3;
	public var decoration:ITextDecoration;
}