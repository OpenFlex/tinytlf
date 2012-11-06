/*
* Copyright (c) 2012 the original author or authors
*
* Permission is hereby granted to use, modify, and distribute this file
* in accordance with the terms of the license agreement accompanying it.
*/
package org.tinytlf.classes
{
	public class CSS extends Styleable
	{
		[Embed(source = "../default.css", mimeType = "application/octet-stream")]
		public static const defaultCSS:Class;
		
		public function CSS(css:String = '')
		{
			super();
			clearStyles();
			inject(css || '');
		}
		
		private var styles:StyleLink;
		
		/**
		 * Queries for all properties derived from the given style path. The
		 * style path should aggregate the nodes, class names, ids, and
		 * pseudoclasses, and sort them in inheritance order (from left to
		 * right).
		 *
		 * @returns An <code>IStyleable</code> instance, with properties that
		 * represent a flattened list of all cascading styles defined by the
		 * style path.
		 */
		public function lookup(path:String):Styleable
		{
			return Cache.getStyle(path) || Cache.cacheStyle(path, internalLookup(path));
		}
		
		//	#id
		//	.class
		//	body p
		//	body p a:active
		//	body p#id a:active
		//	body p #id a:active
		//	body p.class a:active
		//	body p .class a:active
		//	div a#id:active
		//	div a.class:active
		private function internalLookup(path:String):Styleable
		{
			const merged:Styleable = new MergedStyleable();
//			const merged:Styleable = new Styleable();
			
			if(!path)
				return merged;
			
			var link:StyleLink = styles;
			
			path.
				split(' ').
				forEach(function(component:String, ... args):void {
					
					// Pull the top top-level style definitions for this part of
					// the style. For example, if the path is: 'div a:hover',
					// make sure to pull top-level properties for 'a:hover'
					// first, then apply the div's cascading 'a:hover'
					// properties.
					//
					// I think we can get away with a cached lookup here,
					// forcing a manual lookup would be unnecessary work.
					if(component != path)
						merged.mergeWith(lookup(component));
					//	merged.mergeWith(internalLookup(component));
					
					const name:StyleName = Cache.getName(component);
					name.
						styles.
						every(function(part:String, ... args):Boolean {
							if(!link)
								return false;
							
							if((link = link[name[part]]))
								return link.applyStyles(merged, true) && link;
							
							return false;
						});
				});
			
			return merged;
		}
		
		
		/**
		 * Parse and inject any number of CSS blocks. CSS blocks can be as
		 * simple as:
		 * <p><code>
		 *	a {
		 *		color: black;
		 *	}
		 * </code></p>
		 * to as complex as:
		 * <p><code>
		 *	h1,div#content,div#content a,span.title_link,
		 *	span.title_link a,span.title_link a:hover,li a,
		 *	#banner img{
		 *		color:#494949;
		 *		text-shadow:1 1 0 #fff;
		 *	}
		 * </code></p>
		 */
		public function inject(css:String):CSS
		{
			// Strip out all white space between blocks
			css.
				replace(/\s*([@{}:;,]|\)\s|\s\()\s*|\/\*([^*\\\\]|\*(?!\/))+\*\/|[\n\r\t]|(px)/g, '$1').
				// Parse each block
				match(/[^{]*\{([^}]*)*}/g).
				forEach(function(block:String, ... args):void {
					if(!block)return;
					
					// Split the block into two parts: prefix and suffix.
					// prefix is the block style names, suffix is the values.
					var parts:Array = block.split('{');
					const suffix:String = parts.pop().split('}')[0];
					const prefix:String = parts.pop();
					
					// The suffix is easy, build a hashmap of key/value pairs.
					const values:Styleable = new Styleable();
					suffix.
						split(';').
						forEach(function(pair:String, ... args):void {
							if(!pair)return;
							parts = pair.split(':');
							values[parts.shift()] = parts.pop();
						});
					
					// Prefix is trickier. Split on the commas, because comma is
					// the style aggregation token. A prefix of 'h1, h2' means
					// apply this block's values to the top level style
					// dictionary of both h1 and h2, without a cascading
					// relationship.
					prefix.
						split(',').
						forEach(function(component:String, ... args):void {
							if(!component)return;
							
							// The StyleName class encapsulates the cascading
							// relationship for styles, and stores them in a
							// sorted styles array.
							const name:StyleName = Cache.getName(component);
							
							// Start indexing style names at the root.
							var link:StyleLink = styles;
							
							// Iterate through the sorted cascading styles list
							// and move/create nodes for the descendent styles
							// at each level.
							// Apply the values once we've reached the lowest
							// level of the style tree.
							name.
								styles.
								forEach(function(part:String, i:int, a:Array):void {
									link = (link[name[part]] ||= new StyleLink());
									if(i == a.length - 1)
										link.mergeStyles(values);
								});
						});
				});
			
			return this;
		}
		
		public function clearStyles():void
		{
			Cache.clearStyles();
			styles = new StyleLink();
			styles['html'] = styles;
			inject(new defaultCSS().toString());
		}
		
		override public function getStyle(styleProp:String):*
		{
			return styles['html'].getStyle(styleProp);
		}
		
		override public function setStyle(styleProp:String, newValue:*):void
		{
			styles['html'].setStyle(styleProp, newValue);
		}
	}
}
import flash.system.Capabilities;
import flash.utils.flash_proxy;

import org.tinytlf.*;
import org.tinytlf.classes.*;

use namespace flash_proxy;

internal class StyleLink extends Styleable
{
	private const styleNames:Array = [];
	public function get styles():Array
	{
		return styleNames.concat();
	}
	
	override public function setStyle(styleProp:String, newValue:*):void
	{
		const prop:String = styleProp.toString();
		if(prop.indexOf('-') != -1)
			styleProp = convertFromDashed(prop);
		
		const i:int = styleNames.indexOf(styleProp);
		i == -1 ? styleNames.push(styleProp) : styleNames.splice(i, 1, styleProp);
		super.setStyle(styleProp, newValue);
	}
	
	public function mergeStyles(object:Object):Styleable
	{
		for(var prop:String in object)
			setStyle(prop, object[prop]);
		
		return this;
	}
	
	public function applyStyles(destination:Object, dynamic:Boolean = false):Styleable
	{
		styleNames.
			forEach(function(name:String, ... args):void {
				applyProperty(name, destination, dynamic);
			});
		
		return this;
	}
	
	override protected function mergeProperty(property:String, source:Object):void
	{
		const prop:String = property;
		if(prop.indexOf('-') != -1)
			property = convertFromDashed(prop);
		
		this[property] = source[prop];
	}
	
	override flash_proxy function setProperty(name:*, value:*):void
	{
		const prop:String = name.toString();
		if(prop.indexOf('-') != -1)
			name = convertFromDashed(prop);
		
		super.setProperty(name, value);
	}
	
	override flash_proxy function getProperty(name:*):*
	{
		const prop:String = name.toString();
		if(prop.indexOf('-') != -1)
			name = convertFromDashed(prop);
		
		return super.getProperty(name) || defaults[name];
	}
	
	private function convertFromDashed(property:String):String
	{
		return property.split('-').map(function(part:String, i:int, ... args):String {
			return i == 0 ? part : part.charAt(0).toUpperCase() + part.substr(1);
		}).join('');
	}
	
	private static const defaults:Object = {
			padding: 0, paddingLeft: 0, paddingRight: 0, paddingTop: 0,
			paddingBottom: 0, margin: 0, marginLeft: 0, marginRight: 0,
			marginTop: 0, marginBottom: 0, width: 0, height: 0, fontSize: 12
		};
}

use namespace flash_proxy;

internal class MergedStyleable extends Styleable
{
	override flash_proxy function setProperty(name:*, value:*):void
	{
		if(value is String)
		{
			value = processNumberValue(name, value);
		}
		
		super.setProperty(name, value);
	}
	
	private static const screenDPI:Number = Capabilities.screenDPI;
	
	private function processNumberValue(styleProp:String, val:String):*
	{
		const baseValue:Number = hasOwnProperty(styleProp) ? this[styleProp] :
			hasOwnProperty('fontSize') ? this['fontSize'] : NaN;
		
		if(val == '' || baseValue != baseValue)
			return val;
		
		if(val.lastIndexOf('%') == val.length - 1)
			baseValue * Number(val.substring(0, val.indexOf('%')));
		
		if(val.length < 2)
			return val;
		
		if(val.lastIndexOf('em') == val.length - 2)
			return baseValue * Number(val.substring(0, val.indexOf('em')));
		else if(val.lastIndexOf('ex') == val.length - 2)
			return baseValue * Number(val.substring(0, val.indexOf('ex'))) * 0.5;
		else if(val.lastIndexOf('pt') == val.length - 2)
			return (Number(val.substring(0, val.indexOf('pt'))) / 72) * screenDPI;
		else if(val.indexOf('#') == 0)
			return uint('0x' + val.substring(1));
		
		return parseFloat(val) || val;
	}
}

internal class StyleName extends Styleable
{
	////
	//	Style will be in any of the following formats.
	//	div#footer
	//	div.post_content
	//	a:active
	//	div a:active
	//	#banners img
	//	.posts .post
	//	li a
	//	li a:active
	////
	public function StyleName(style:String)
	{
		super();
		
		var parts:Array;
		var prefix:String
		var suffix:String;
		
		const thisObj:StyleName = this;
		var k:int = 0;
		
		style.
			split(' ').
			forEach(function(part:String, i:int, ... args):void {
				const n:String = (Math.round(Math.random() * (9999999 * (i + 1)))).toString();
				
				if(part.indexOf(':') != -1)
				{
					parts = part.split(':');
					thisObj.mergeWith(Cache.getName(parts.shift()));
					const pclass:String = parts.pop();
					thisObj['pseudoclass_' + pclass + ': ' + n] = pclass;
				}
				else if(part.indexOf('.') != -1)
				{
					parseClassOrId(part, 'className', '.', n);
				}
				else if(part.indexOf('#') != -1)
				{
					parseClassOrId(part, 'id', '#', n);
				}
				else
				{
					thisObj['element_' + part + ': ' + n] = part;
				}
			});
	}
	
	private function parseClassOrId(style:String, property:String, token:String, id:String = ''):void
	{
		const parts:Array = style.split(token);
		const suffix:String = parts.pop();
		const prefix:String = parts.pop();
		
		if(prefix)
		{
			this['element_' + prefix + ': ' + id] = prefix;
		}
		
		if(suffix.indexOf(' ') != -1)
		{
			mergeWith(Cache.getName(suffix));
			const first:String = suffix.split(' ').shift();
			this[property + '_' + first + ': ' + id] = token + first;
		}
		else
		{
			this[property + '_' + suffix + ': ' + id] = '#' + suffix;
		}
	}
	
	public function get styles():Array
	{
		return propNames.concat();
	}
}

internal class Cache
{
	public static function clearStyles():void
	{
		styleCache = {};
	}
	
	private static const nameCache:Object = {};
	public static function getName(name:String):StyleName
	{
		return nameCache[name] ||= new StyleName(name);
	}
	
	private static var styleCache:Object = {};
	public static function getStyle(lookup:String):Styleable
	{
		return styleCache[lookup];
	}
	
	public static function cacheStyle(path:String, style:Styleable):Styleable
	{
		return styleCache[path] = style;
	}
}
