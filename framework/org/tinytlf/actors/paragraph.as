package org.tinytlf.actors
{
	import asx.array.last;
	import asx.fn._;
	import asx.fn.args;
	import asx.fn.aritize;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.sequence;
	import asx.object.newInstance_;
	
	import flash.display.DisplayObjectContainer;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	public function paragraph(element:DOMElement/*<XML>*/,
							   containerFactory:Function,
							   childFactory:Function):IObservable/*Array<DOMElement, DisplayObject>*/ {
		
		const rendered:ISubject = element.rendered;
		const container:DisplayObjectContainer = containerFactory(element.key)(element);
		const region:Region = element.region;
		const widths:IObservable = region.widthSubj.takeUntil(element.count());
		
		const distinct:IObservable = element.distinctUntilChanged();
		
		const updates:IObservable = distinct.combineLatest(widths, args);
		
		const selectVisible:Function = function(node:XML, width:Number):IObservable {
			container.removeChildren();
			
			return content(containerFactory, node).
				map(partial(block, node)).
				mapMany(partial(lines, width));
		};
		
		const reportUpdate:Function = sequence(
			sequence(args, last, ifElse(
				not(container.contains),
				container.addChild,
				noop
			)),
			updateEvent,
			container.dispatchEvent
		);
		
		const expandUpdate:Function = function(...args):IObservable {
			container.dispatchEvent(renderEvent());
			return Observable.value([element, container]);
		};
		
		const virtualizationObs:IObservable = virtualize(element, updates, selectVisible, reportUpdate, expandUpdate);
		const similar:IObservable = element.distinctUntilChanged(not(theSame)).
			skip(1).
			switchMany(expandUpdate);
		
		const lifetimeObs:IObservable = virtualizationObs.merge(similar).takeUntil(element.count());
		
		return lifetimeObs.peek(
			function(values:Array):void {
				Scheduler.defaultScheduler.schedule(partial(rendered.onNext, values));
				Scheduler.defaultScheduler.schedule(rendered.onCompleted);
			},
			noop,
			printError('paragraph2: ' + element.key, true)
		);
	}
}
import asx.array.first;
import asx.fn.I;
import asx.fn._;
import asx.fn.aritize;
import asx.fn.partial;
import asx.fn.sequence;
import asx.object.newInstance_;

import flash.text.engine.ContentElement;
import flash.text.engine.GroupElement;
import flash.text.engine.TextBlock;
import flash.text.engine.TextElement;
import flash.text.engine.TextLine;

import org.tinytlf.enumerables.childrenOfXML;
import org.tinytlf.lambdas.createTextLine;
import org.tinytlf.lambdas.getLineBeforeFirstInvalidLine;
import org.tinytlf.lambdas.getValidLines;
import org.tinytlf.lambdas.isBlockInvalid;
import org.tinytlf.lambdas.setupTextBlock;
import org.tinytlf.lambdas.toElementFormat;
import org.tinytlf.pools.TextBlocks;
import org.tinytlf.types.Styleable;

import raix.reactive.IObservable;
import raix.reactive.Observable;
import raix.reactive.scheduling.Scheduler;

internal function theSame(a:XML, b:XML):Boolean {
	return a && b && a === b;
}

internal function content(childFactory:Function, node:XML):IObservable {
	
	const name:String = node.localName();
	const numChildren:int = node.*.length();
	
	if(numChildren == 0) {
		const element:ContentElement = (
			aritize(childFactory(name), 2)(node) ||
			new TextElement(node.toString(), toElementFormat(null))
		);
		
		return Observable.value(element);
	}
	
	const childObservables:Array = childrenOfXML(node).
		map(partial(content, childFactory)).
		toArray();
	
	return (
		childObservables.length == 1 ? 
		first(childObservables).map(partial(newInstance_, Array)) :
		Observable.forkJoin(childObservables)
	).
		map(function(elements:Array):Vector.<ContentElement>{
			return Vector.<ContentElement>(elements);
		}).
		map(partial(newInstance_, GroupElement, _, toElementFormat(null)));
};

internal function block(node:XML, content:ContentElement):TextBlock {
	return setupTextBlock(TextBlocks.checkOut(), content, new Styleable());
};

internal function lines(width:Number, block:TextBlock):IObservable {
	
	var breakAnother:Boolean = false;
	
	const predicate:Function = function(line:TextLine):Boolean {
		return breakAnother;
	};
	
	const iterate:Function = function(line:TextLine):TextLine {
		
		// gimme me a textline.
		line = createTextLine(block, line, width);
		
		// break another while the block is still invalid.
		breakAnother = isBlockInvalid(block);
		
		return line;
	};
	
	// If the block is invalid, it's possible there's some valid lines.
	// Don't re-render all the lines if we don't have to.
	if(isBlockInvalid(block)) {
		
		// Get valid lines to start from.
		const validLines:Array = getValidLines(block);
		
		// Check in old lines.
		// TextLines.checkIn.apply(null, getInvalidLines(block));
		
		// Start from a line, but can be null.
		const initial:TextLine = getLineBeforeFirstInvalidLine(block);
		
		// Concat the valid and new lines together.
		return Observable.concat([
			Observable.fromArray(validLines),
			Observable.generate(initial || iterate(null), predicate, iterate, I)
		]);
	}
	
	breakAnother = true;
	
	// Render all the lines.
	return Observable.generate(iterate(null), predicate, iterate, I, Scheduler.greenThread);
};