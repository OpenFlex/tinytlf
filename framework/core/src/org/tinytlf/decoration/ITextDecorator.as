/*
 * Copyright (c) 2010 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package org.tinytlf.decoration
{
	/**
	 * ITextDecorator is the decoration actor for tinytlf. <code>ITextDecorator</code> 
	 * is a map for defining text decorations, including what they're called and
	 * the classes or instances which draw the decoration.
	 * <code>ITextDecorator</code> also manages the application and rendering of 
	 * decorations. Use <code>decorate</code> and <code>undecorate</code> to 
	 * apply or un-apply a decoration to an element. <code>ITextDecorator</code> 
	 * handles invalidating and rendering the decorations.
	 */
    public interface ITextDecorator
    {
		/**
		 * Creates a decoration at the specified <code>layer</code> for the 
		 * <code>element</code> based on the <code>styleObj</code>. An optional
		 * <code>containers</code> argument can be supplied if it is known which
		 * <code>ITextContainer</code>s this decoration will render onto. This
		 * is an optimization, as the <code>ITextContainers</code> can be 
		 * determined at render time, though it can be an expensive operation.
		 * 
		 * <p>
		 * The element type is deliberately ambiguous, as it's up to the 
		 * implementor to support different types. In the core 
		 * <code>TextDecorator</code>, <code>element</code> can be one of four 
		 * types:
		 * <ol>
		 * <li>A <code>flash.text.engine.ContentElement</code>.</li>
		 * <li>A <code>flash.text.engine.TextLine</code>.</li>
		 * <li>A <code>flash.geom.Rectangle</code>.</li>
		 * <li>A Vector of <code>flash.geom.Rectangle</code>s.</li>
		 * </ol>
		 * If the type is a <code>ContentElement</code>, the optional
		 * <code>containers</code> vector is ignored, as 
		 * <code>ITextContainers</code> can't be associated for a
		 * <code>ContentElement</code> until render time.
		 * </p>
		 * 
		 * <p>
		 * The <code>layer</code> property defines which layer the decoration
		 * should exist on. Smaller numbers are closer to the z-order top, with
		 * 0 being the "highest" allowed layer. The <code>ITextEngine</code>'s 
		 * caret decoration is on layer 0, and the selection decoration is on
		 * layer 1.
		 * </p>
		 * 
		 * @see org.tinytlf.decor.TextDecorator
		 */
        function decorate(element:*, styleObject:Object, layer:int = 3, foreground:Boolean = false):void;
		
		/**
		 * <code>Undecorate</code> has three expected functions:
		 * <ul>
		 * <li>If <code>element</code> and <code>decorationProp</code> are 
		 * specified, <code>undecorate</code> removes a the specified 
		 * <code>decorationProp</code> from the element.</li>
		 * <li>If <code>element</code> is specified with no 
		 * <code>decorationProp</code>, <code>undecorate</code> removes all 
		 * decorations for the <code>element</code>.</li>
		 * <li>If <code>decorationProp</code> is specified with no 
		 * <code>element</code>, <code>undecorate</code> removes all instances 
		 * of the decoration from all elements in the 
		 * <code>ITextDecorator</code>.</li>
		 * </ul>
		 * 
		 * @see org.tinytlf.decor.ITextDecoration
		 */
        function undecorate(element:* = null, decorationProp:String = null):void;
		
		/**
		 * Renders all the decorations in the text field.
		 * 
		 * @see org.tinytlf.ITextEngine#invalidateDecorations()
		 */
		function render():void;
		
		/**
		 * Removes all the decorations in the text field.
		 */
		function removeAll():void;
    }
}

