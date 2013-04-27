package org.tinytlf.parsers.block
{
	import asx.array.pluck;
	
	import flash.geom.Rectangle;
	
	import org.tinytlf.enumerables.cachedValues;
	
	import trxcllnt.ds.HRTree;

	/**
	 * @author ptaylor
	 */
	internal function allowContainerUpdate(a:Array, b:Array):Boolean {
		// If either is null, do an update.
		if(!a || !b) return true;
		
		const oldToString:String = b[0];
		const newToString:String = a[0];
		
		// If their styles changed, do an update.
		if(oldToString != newToString) return true;
		
		const oldnode:XML = a[1];
		const newnode:XML = b[1];
		
		// If the node child list differs, do an update.
		if(oldnode.*.length() != newnode.*.length()) return true;
		
		const oldport:Rectangle = a[2];
		const newport:Rectangle = b[2];
		const cache:HRTree = b[3];
		const mbr:Rectangle = cache.mbr;
		
		// If the cache is smaller than the viewport, do an update.
		if(mbr.bottom < newport.bottom) return true;
		
		const oldKeys:Array = pluck(cachedValues(cache, oldport), 'key');
		const newKeys:Array = pluck(cachedValues(cache, newport), 'key');
		
		const oldStr:String = '[' + oldKeys.join('], [') + ']';
		const newStr:String = '[' + newKeys.join('], [') + ']';
		
		// If there are different children in view, do an update.
		return oldStr != newStr;
	}
}