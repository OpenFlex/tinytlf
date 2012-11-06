package org.tinytlf.box
{
	import org.swiftsuspenders.*;
	import org.tinytlf.html.*;
	
	/**
	 * <p>
	 * ClosureBoxFactory is a Box factory which creates an Array of
	 * Boxes with a closure.
	 * </p>
	 * 
	 * <p>
	 * If the creation closure accepts two arguments, the first must be an
	 * IDOMNode and the second a Box. In this case, ClosureTRF ensures
	 * the supplied <code>parse</code> and <code>render</code> functions are 
	 * called when the Box's <code>parse()</code> and
	 * <code>render()</code> functions are called.
	 * </p>
	 * 
	 * <p>
	 * The parse function can accept nothing, or a Box. It should
	 * return an array of Boxes to be rendered.
	 * </p>
	 * 
	 * <p>
	 * The render function can accept nothing, or a Box. It should
	 * return nothing, a DisplayObject, or an Array of DisplayObjects. If it
	 * returns DisplayObjects, they will be added to the display list.
	 * </p>
	 */
	public class ClosureBoxFactory implements IBoxFactory
	{
		public function ClosureBoxFactory(injector:Injector, create:Function = null, parse:Function = null, render:Function = null)
		{
			this.injector = injector;
			createFunc = create || function():Array {return [];};
			parseFunc = parse;
			renderFunc = render;
		}
		
		private var injector:Injector;
		private var createFunc:Function;
		private var parseFunc:Function;
		private var renderFunc:Function;
		
		public function create(dom:IDOMNode):Array
		{
			const val:* = createFunc.length == 2 ?
				createFunc(dom, new ClosureRectangle(injector, parseFunc, renderFunc)) :
				createFunc.length == 1 ?
					createFunc(dom) :
					createFunc();
			
			return val ? val is Array ? val : [val] : [];
		}
	}
}
import flash.display.*;

import org.swiftsuspenders.*;
import org.tinytlf.box.*;
import org.tinytlf.box.progression.*;

internal class ClosureRectangle extends Box
{
	public function ClosureRectangle(injector:Injector, parseF:Function = null, renderF:Function = null)
	{
		this.injector = injector;
		parseFunc = parseF || function(box:Box):Array {return [];};
		renderFunc = renderF || function(box:Box):Array {return box.children;};
	}
	
	private var parseFunc:Function;
	private var renderFunc:Function;
	
	override protected function internalParse():Array
	{
		const val:* = parseFunc.length == 1 ? parseFunc(this) : parseFunc();
		return val ? val is Array ? val : [val] : [];
	}
	
	override public function render():Array
	{
		progression.alignment = getAlignmentForProgression(textAlign, blockProgression);
		invalid = false;
		const val:* = renderFunc.length == 1 ? renderFunc(this) : renderFunc();
		return val ? val is Array ? val : val is DisplayObject ? [val] : children : children;
	}
}
