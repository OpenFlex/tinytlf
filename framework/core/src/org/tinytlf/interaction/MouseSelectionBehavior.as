package org.tinytlf.interaction
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.*;
	import flash.geom.Point;
	import flash.text.engine.*;
	import flash.ui.*;
	
	import org.tinytlf.*;
	import org.tinytlf.box.*;
	import org.tinytlf.util.*;
	import org.tinytlf.virtualization.*;
	
	import raix.reactive.*;
	
	public class MouseSelectionBehavior extends EventBehavior
	{
		[Inject('layout')]
		public var llv:Virtualizer;
		
		[Inject('content')]
		public var cllv:Virtualizer;
		
		[PostConstruct]
		override public function initialize():void
		{
			super.initialize();
			
			enabled = true;
		}
		
		private var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			if(value == enabled)
				return;
			
			_enabled = value;
			invalidate();
		}
		
		private var moveCancelable:ICancelable;
		private var downCancelable:ICancelable;
		private var rollOutCancelable:ICancelable;
		private var dragCancelable:ICancelable;
		
		override protected function subscribe():void
		{
			if(!enabled)
				return;
			
			cancel();
			
			downCancelable = obs.down.subscribe(onDown);
			dragCancelable = obs.drag.subscribe(onDrag);
			
			return;
			moveCancelable = obs.rollOver.take(1).subscribe(function(me:MouseEvent):void {
				
				const previousCursor:String = Mouse.cursor;
				Mouse.cursor = MouseCursor.IBEAM;
				
				if(rollOutCancelable) rollOutCancelable.cancel();
				
				rollOutCancelable = obs.rollOut.subscribe(function(me:MouseEvent):void {
					Mouse.cursor = previousCursor;
					
					if(rollOutCancelable) rollOutCancelable.cancel();
					rollOutCancelable = null;
					
					if(moveCancelable) moveCancelable.cancel();
					moveCancelable = null;
					
					subscribe();
				});
			});
		}
		
		override protected function cancel():void
		{
			super.cancel();
			
			if(downCancelable) downCancelable.cancel();
			if(moveCancelable) moveCancelable.cancel();
			if(rollOutCancelable) rollOutCancelable.cancel();
			if(dragCancelable) dragCancelable.cancel();
			
			downCancelable = null;
			moveCancelable = null;
			rollOutCancelable = null;
			dragCancelable = null;
		}
		
		override protected function intersectionFilter(me:MouseEvent):Boolean
		{
			return true;
		}
		
		override protected function onRender(event:Event):void
		{
			engine.removeEventListener(Event.RENDER, onRender);
			invalidated = false;
			enabled ? subscribe() : cancel();
		}
		
		protected function onDown(me:MouseEvent):void
		{
			const index:int = engine.getCharIndexAtPoint(me.stageX, me.stageY);
			engine.select(index, index);
		}
		
		protected function onDrag(me:MouseEvent):void
		{
			const index:int = engine.getCharIndexAtPoint(me.stageX, me.stageY);
			const selection:Point = engine.selection.clone();
			selection.x = Math.min(selection.x, index);
			selection.y = Math.max(selection.y, index);
			engine.select(selection.x, selection.y);
		}
	}
}
