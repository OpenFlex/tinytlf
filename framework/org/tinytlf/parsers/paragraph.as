package org.tinytlf.parsers
{
	import asx.array.last;
	import asx.fn.args;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.fn.sequence;
	
	import flash.display.DisplayObjectContainer;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.handlers.printError;
	import org.tinytlf.renderers.content;
	import org.tinytlf.renderers.lines;
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.DOMNode;
	import org.tinytlf.types.Region;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.Scheduler;
	
	import trxcllnt.vr.virtualize;

	/**
	 * @author ptaylor
	 */
	public function paragraph(element:DOMElement/*<DOMNode>*/,
							  uiFactory:Function,
							  parserFactory:Function):IObservable/*Array<DOMElement, DisplayObject>*/ {
		
		const root:CSS = uiFactory('css')();
		
		const rendered:ISubject = element.rendered;
		const container:DisplayObjectContainer = uiFactory(element.key)(element);
		const region:Region = element.region;
		const widths:IObservable = region.widthSubj.takeUntil(element.count());
		
		const distinct:IObservable = element.distinctUntilChanged();
		
		const updates:IObservable = distinct.combineLatest(widths, args);
		
		const selectVisible:Function = function(node:DOMNode, width:Number):IObservable {
			container.removeChildren();
			
			return content(uiFactory, node, root).
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
			printError('paragraph: ' + element.key, true)
		);
	}
}
import asx.fn.partial;
import asx.fn.sequence;

import flash.text.engine.ContentElement;
import flash.text.engine.TextBlock;

import org.tinytlf.lambdas.setupTextBlock;
import org.tinytlf.pools.TextBlocks;
import org.tinytlf.types.DOMNode;

import raix.reactive.IObservable;
import raix.reactive.Observable;
import raix.reactive.scheduling.Scheduler;

internal function theSame(a:DOMNode, b:DOMNode):Boolean {
	return a && b && a.node === b.node;
}

internal function block(node:DOMNode, content:ContentElement):TextBlock {
	return setupTextBlock(TextBlocks.checkOut(), content, node);
};
