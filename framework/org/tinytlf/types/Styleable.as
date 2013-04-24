/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package org.tinytlf.types
{
	import flash.utils.*;
	
	use namespace flash_proxy;
	
	/**
	 * <p>
	 * Styleable is a useful base class for objects with sealed properties
	 * but who also wish to dynamically accept and store named values.
	 * </p>
	 * 
	 * <p>
	 * Since it extends Proxy, it overrides the flash_proxy functions for setting
	 * and retrieving data. If you are calling a sealed property on
	 * Styleable or one of his subclasses, the property or function is called
	 * like normal. However, if you dynamically set or call a property on it,
	 * <code>getStyle</code> and <code>setStyle</code> are called instead.
	 * </p>
	 *
	 * <p>
	 * Styleable has a <code>style</code> member, on which the style
	 * properties and values are stored. You can pass in your own dynamic
	 * instance to store styles on by setting the <code>style</code> setter.
	 * This will set the new value as the internal styles storage object, as
	 * well as copy over all the key/value pairs currently on the new instance.
	 * </p>
	 */
	public dynamic class Styleable extends Proxy
	{
		public function Styleable(styleObject:Object = null)
		{
			mergeWith(styleObject);
		}
		
		protected var properties:Object = {};
		protected var propNames:Array = [];
		
		public function clearStyle(styleProp:String):Boolean
		{
			return delete this[styleProp];
		}
		
		public function clearStyles():Styleable
		{
			properties = {};
			propNames.length = 0;
			return this;
		}
		
		public function getStyle(styleProp:String):*
		{
			return this[styleProp];
		}
		
		public function setStyle(styleProp:String, newValue:*):void
		{
			this[styleProp] = newValue;
		}
		
		public function mergeWith(object:Object):Styleable
		{
			for(var prop:String in object)
				mergeProperty(prop, object);
			
			return this;
		}
		
		public function unmergeWith(object:Object):Styleable
		{
			for(var prop:String in object)
				unmergeProperty(prop);
			
			return this;
		}
		
		public function applyTo(object:Object, dynamic:Boolean = false):Styleable
		{
			for(var prop:String in properties)
				applyProperty(prop, object, dynamic);
			
			return this;
		}
		
		public function unapplyTo(object:Object):Styleable
		{
			for(var prop:String in properties)
				unapplyProperty(prop, object);
			
			return this;
		}
		
		public function toString():String
		{
			var str:String = "{";
			propNames.forEach(function(property:String, ...args):void{
				str = str.concat(property, ":", properties[property].toString(), ";");
			});
			return str.concat("}");
		}
		
		protected function mergeProperty(property:String, source:Object):void
		{
			this[property] = source[property];
		}
		
		protected function unmergeProperty(property:String):void
		{
			delete this[property];
		}
		
		protected function applyProperty(property:String, destination:Object, dynamic:Boolean = false):void
		{
			if(!destination.hasOwnProperty(property) && !dynamic)
				return
			
			const isFunction:Boolean = destination[property] is Function;
			if(isFunction)
				return;
			
			if(dynamic)
				destination[property] = this[property];
			else if(property in destination)
				destination[property] = this[property];
		}
		
		protected function unapplyProperty(property:String, destination:Object):void
		{
			if(property in destination && !(destination[property] is Function))
				delete destination[property];
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			return properties[name];
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return properties.hasOwnProperty(name);
		}
		
		override flash_proxy function callProperty(name:*, ... parameters):*
		{
			if(properties.hasOwnProperty(name))
				return function(... args):*{return properties[name]};
			
			return null;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			if(delete properties[name])
			{
				propNames.splice(propNames.indexOf(name.toString()), 1);
				return true;
			}
			
			return false;
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			if(!properties.hasOwnProperty(name))
				propNames.push(name.toString());
			
			properties[name] = value;
		}
		
		override flash_proxy function nextName(index:int):String
		{
			return propNames[index - 1];
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			if(index < propNames.length)
				return index + 1;
			else
				return 0;
		}
		
		override flash_proxy function nextValue(index:int):*
		{
			return properties[propNames[index - 1]];
		}
	}
}

