package org.tinytlf.util
{
	import flash.display.*;
	import flash.geom.*;
	import flash.text.engine.*;
	import flash.utils.*;
	
	public final class TextLineUtil
	{
		/**
		 * Returns the index of the atom at a particular point. If the point
		 * is outside the boundaries of the line, this determines which side the
		 * point is on, and returns 0 or line.atomCount.
		 */
		public static function getAtomIndexAtPoint(line:TextLine, x:Number, y:Number):int
		{
			if(!line) return -1;
			
			var index:int = line.getAtomIndexAtPoint(x, y);
			
			if(index < 0)
			{
				const bounds:Rectangle = line.getBounds(line.stage);
				const center:Point = bounds.topLeft.clone();
				center.offset(bounds.width * .5, bounds.height * .5);
				
				if(y < bounds.y)
					return 0;
				if(y > bounds.y && y < bounds.y + bounds.height)
					return line.atomCount;
				
				index = (x < center.x) ? 0 : line.atomCount;
			}
			
			const atomIncrement:int = getAtomSide(line, x, y) ? 0 : 1;
			
			return Math.max(index + atomIncrement, 0);
		}
		
		/**
		 * Finds which side of the atom the point is on.
		 * @returns true for left, false for right.
		 */
		public static function getAtomSide(line:TextLine, x:Number, y:Number):Boolean
		{
			var atomIndex:int = line.getAtomIndexAtPoint(x, y);
			
			if(atomIndex < 0)
				return true;
			
			var center:Number = line.getAtomCenter(atomIndex);
			var pt:Point = line.localToGlobal(new Point(center));
			
			return pt.x > x;
		}
		
		private static const defaultWordBoundaryPattern:RegExp = /\W+|\b[^\W﷯]*/;
		private static const nonWordPattern:RegExp = /\W/;
		
		/**
		 * Finds the next/prev word boundary specified by the direction and the
		 * boundaryPattern. If no boundary pattern is specified, the default
		 * is used, which matches non-word characters or graphic characters.
		 */
		public static function getAtomWordBoundary(line:TextLine, atomIndex:int,
												   left:Boolean = true, boundaryPattern:RegExp = null):int
		{
			if(!boundaryPattern)
				boundaryPattern = defaultWordBoundaryPattern;
			
			if(atomIndex >= line.atomCount)
				atomIndex = line.atomCount - 1;
			else if(atomIndex < 0)
				atomIndex = 0;
			
			var rawText:String = line.textBlock.content.rawText;
			var adjustedIndex:int = line.getAtomTextBlockBeginIndex(atomIndex);
			
			// If the index is already at a word boundary,
			// move to find the next word boundary.
			while(nonWordPattern.test(rawText.charAt(adjustedIndex)))
			{
				adjustedIndex += left ? -1 : 1;
				atomIndex += left ? -1 : 1;
			}
			
			var text:String = left ?
				rawText.slice(0, adjustedIndex).split("").reverse().join("") :
				rawText.slice(adjustedIndex, rawText.length);
			
			var match:Array = boundaryPattern.exec(text);
			if(match)
			{
				var str:String = String(match[0]);
				atomIndex += nonWordPattern.test(str) ? 0 : str.length * (left ? -1 : 1);
			}
			
			return Math.max(atomIndex, 0);
		}
		
		/**
		 * Recursively drills down into the ContentElement of the TextLine's
		 * TextBlock to return the leaf element at the specified atomIndex.
		 */
		public static function getElementAtAtomIndex(line:TextLine, atomIndex:int):ContentElement
		{
			if(atomIndex < 0)
				return null;
			
			return ContentElementUtil.getLeaf(line.textBlock.content,
											  line.textBlockBeginIndex + atomIndex);
		}
		
		/**
		 * Returns a Vector of ContentElements rendered in the given TextLine.
		 * This can only return the elements that have specified eventMirrors,
		 * so it's not guaranteed to be every ContentElement.
		 */
		public static function getContentElements(line:TextLine):Vector.<ContentElement>
		{
			const block:TextBlock = line.textBlock;
			const beginIndex:int = line.textBlockBeginIndex;
			const endIndex:int = beginIndex + line.atomCount;
			const elements:Vector.<ContentElement> = new <ContentElement>[];
			
			var index:int = beginIndex;
			var content:ContentElement = ContentElementUtil.getLeaf(block.content, index);
			
			while(content)
			{
				elements.push(content);
				index += content.rawText.length;
				content = ContentElementUtil.getLeaf(block.content, index);
			}
			
			return elements;
		}
		
		public static function getMirrorRegionForElement(line:TextLine, element:ContentElement):TextLineMirrorRegion
		{
			if(!line.mirrorRegions)
				return null;
			
			var regions:Vector.<TextLineMirrorRegion> = line.mirrorRegions;
			var region:TextLineMirrorRegion;
			var n:int = regions.length;
			
			for(var i:int = 0; i < n; i += 1)
			{
				region = regions[i];
				if(region.element === element)
					return region;
			}
			
			return null;
		}
		
		public static function hasLineBreak(line:TextLine):Boolean
		{
			if(line.atomCount <= 1)
				return false;
			
			//Check to see if we have a line break graphic at the end of the TextLine
			var graphicIndex:int = line.atomCount - 1;
			var dObj:DisplayObject = line.getAtomGraphic(graphicIndex);
			if(!dObj)
				return false;
			
			//We have some kind of graphic at the end, is it a line break?
			var g:GraphicElement = GraphicElement(getElementAtAtomIndex(line, graphicIndex));
			return g.userData === 'lineBreak';
		}
		
		public static function cleanLine(line:TextLine):TextLine
		{
			if(line.parent)
				line.parent.removeChild(line);
			
			line.userData = null;
			
			return line;
		}
		
		private static const lines:Dictionary = new Dictionary(false);
		public static var numLines:int = 0;
		
		public static function checkIn(line:TextLine):void
		{
			if(line in lines)
				return;
			
			++numLines;
			lines[line] = true;
		}
		
		public static function checkOut():TextLine
		{
			for(var line:* in lines)
			{
				delete lines[line];
				--numLines;
				return line;
			}
			
			return null;
		}
	}
}
