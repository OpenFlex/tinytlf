/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package org.tinytlf.constants
{
    public final class TextAlign
    {
        public static const LEFT:String = 'left';
        public static const CENTER:String = 'center';
        public static const RIGHT:String = 'right';
        public static const JUSTIFY:String = 'justify';
		
		public static function isValid(value:String):Boolean
		{
			return value == LEFT || value == CENTER || value == RIGHT || value == JUSTIFY;
		}
		
		public static function throwArgumentError(value:String):void
		{
			throw new ArgumentError('TextAlign ' + value + ' is invalid.');
		}
    }
}