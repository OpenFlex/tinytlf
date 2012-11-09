package org.tinytlf.classes
{
	import com.bit101.components.ScrollBar;
	
	import flash.display.*;
	import flash.events.*;

	public class Container extends Sprite
	{
		public function Container(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super();
			x = xpos;
			y = ypos;
			if(parent) {
				parent.addChild(this);
			}
			
			$addChild(container);
		}
		
		protected var container:DisplayObjectContainer = new Sprite();
		protected var scrollBar:ScrollBar = new ScrollBar('vertical');
		
		override public function addChild(child:DisplayObject):DisplayObject {
			return container.addChild(child);
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
			return container.addChildAt(child, index);
		}
		
		override public function contains(child:DisplayObject):Boolean {
			return container.contains(child);
		}
		
		override public function getChildAt(index:int):DisplayObject {
			return container.getChildAt(index);
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject {
			return container.removeChild(child);
		}
		
		override public function removeChildAt(index:int):DisplayObject {
			return container.removeChildAt(index);
		}
		
		override public function removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void {
			return container.removeChildren(beginIndex, endIndex);
		}
		
		override public function get numChildren():int {
			return container.numChildren;
		}
		
		public function $addChild(child:DisplayObject):DisplayObject {
			return super.addChild(child);
		}
		
		public function $contains(child:DisplayObject):Boolean {
			return super.contains(child);
		}
		
		public function $getChildAt(index:int):DisplayObject {
			return super.getChildAt(index);
		}
		
		public function $removeChild(child:DisplayObject):DisplayObject {
			return super.removeChild(child);
		}
		
		public function $removeChildren(beginIndex:int=0, endIndex:int=int.MAX_VALUE):void {
			super.removeChildren(beginIndex, endIndex);
		}
		
		public function get $numChildren():int {
			return super.numChildren;
		}
		
		private var _height:Number = 0;
		override public function get height():Number {
			return _height;
		}
		
		override public function set height(h:Number):void {
			_height = h;
			dispatchEvent(new Event(Event.RESIZE));
		}
		
		private var _width:Number = 0;
		override public function get width():Number {
			return _width;
		}
		
		override public function set width(w:Number):void {
			_width = w;
			dispatchEvent(new Event(Event.RESIZE));
		}
	}
}