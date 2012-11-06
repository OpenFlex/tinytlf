package org.tinytlf
{
	import flash.utils.*;
	
	import org.swiftsuspenders.*;
	import org.tinytlf.content.*;
	import org.tinytlf.decoration.*;
	import org.tinytlf.interaction.*;
	import org.tinytlf.box.*;
	
	public class FactoryMap implements ITextDecorationMap, IContentElementFactoryMap, IEventMirrorMap, IBoxFactoryMap
	{
		public function FactoryMap(factory:* = null)
		{
			if(factory)
			{
				defaultFactory = factory;
			}
		}
		
		[Inject]
		public var injector:Injector;
		
		private var defaultFactoryValue:*;
		
		public function get defaultFactory():*
		{
			return defaultFactoryValue;
		}
		
		public function set defaultFactory(value:*):void
		{
			defaultFactoryValue = null;
			
			if(value is Class || value is Function || value)
				defaultFactoryValue = value;
			
			if(!defaultFactoryValue)
				throw new Error();
		}
		
		private const map:Dictionary = new Dictionary(false);
		
		public function hasMapping(value:*):Boolean
		{
			return map.hasOwnProperty(value);
		}
		
		public function mapFactory(value:*, factory:*):void
		{
			map[value] = factory;
		}
		
		public function unmapFactory(value:*):Boolean
		{
			return delete map[value];
		}
		
		public function instantiate(value:*):*
		{
			const factory:* = (value && map[value]) ? map[value] : defaultFactoryValue;
			var item:*;
			
			if(factory is Class)
				item = new (factory as Class)();
			else if(factory is Function)
				item = (factory as Function)();
			else if(factory)
				item = factory;
			
			if(item)
			{
				injector.injectInto(item);
			}
			
			return item;
		}
	}
}