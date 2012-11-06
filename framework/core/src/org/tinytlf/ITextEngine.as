/*
 * Copyright (c) 2010 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package org.tinytlf
{
	import flash.events.*;
	import flash.geom.*;
	
	/**
	 * ITextEngine is the invalidation and rendering coordinator in tinytlf.
	 * It's also responsible for certain framework-wide properties, such as
	 * caretIndex, scrollPosition, and selection indicies.
	 */
	public interface ITextEngine extends IEventDispatcher
	{
		/**
		 * The index of the selection caret for the engine.
		 */
		function get caret():int;
		
		/**
		 * The scroll position of the engine. This value is in pixels. Defined
		 * centrally here, but usually only needed during layout.
		 */
		function get scroll():Point;
		function set scroll(value:Point):void;
		
		/**
		 * A point whose <code>x</code> property represents the engine's
		 * selection startIndex and <code>y</code> property represents
		 * the engine's selection endIndex.
		 */
		function get selection():Point;
		
		/**
		 * Returns the character index of the item at the given stage point.
		 */
		function getCharIndexAtPoint(stageX:int, stageY:int):int;
		
		/**
		 * Selects the text between the given start and end indicies.
		 */
		function select(startIndex:Number = NaN, endIndex:Number = NaN):void;
		
		/**
		 * Invalidates the lines and decorations.
		 *
		 * @see org.tinytlf.layout.ITextLayout
		 * @see org.tinytlf.decor.ITextDecoration
		 */
		function invalidate():void;
		
		/**
		 * An optimization to invalidate only the lines for re-draw on the next
		 * screen refresh. This runs <code>ITextLayout</code>'s
		 * <code>render</code> routine, which should be optimized to only render
		 * the lines which the FTE's <code>TextBlock</code> has marked as
		 * invalid.
		 *
		 * @see org.tinytlf.layout.ITextLayout
		 */
		function invalidateLines():void;
		
		/**
		 * An optimization to invalidate only the decorations for re-draw on the
		 * next screen refresh. This runs the <code>ITextDecor</code>'s
		 * <code>render</code> routine for rendering
		 * <code>ITextDecoration</code>s.
		 *
		 * @see org.tinytlf.decor.ITextDecoration
		 */
		function invalidateDecorations():void;
		
		/**
		 * Renders the lines and decorations if they've been invalidated.
		 */
		function render():void;
	}
}

