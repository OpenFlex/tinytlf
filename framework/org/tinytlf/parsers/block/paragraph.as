package org.tinytlf.parsers.block
{
	import asx.array.tail;
	import asx.fn.K;
	import asx.fn.apply;
	import asx.fn.aritize;
	import asx.fn.distribute;
	import asx.fn.ifElse;
	import asx.fn.noop;
	import asx.fn.not;
	import asx.fn.pull;
	import asx.fn.sequence;
	
	import flash.display.DisplayObjectContainer;
	import flash.text.engine.ContentElement;
	import flash.text.engine.TextBlock;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.events.updateEvent;
	import org.tinytlf.observables.Values;
	import org.tinytlf.parsers.inline.span;
	import org.tinytlf.pools.TextLines;
	import org.tinytlf.renderers.lines;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.subjects.BehaviorSubject;
	
	import trxcllnt.vr.Virtualizer;

	/**
	 * @author ptaylor
	 */
	public function paragraph(create:Function,
							  renderBlock:Function,
							  renderInline:Function,
							  values:Values):IObservable /*<Values, DisplayObject>*/ {
		
		const view:DisplayObjectContainer = create(values);
		
		const finished:IObservable = Observable.value([values, view]).
			peek(function(...args):void {
				// NOTE: I should be returning an Observable that dispatches
				// when the UI dispatches the "rendered" event, but my layout
				// algorithms are synchronous, and returning a value Observable
				// avoids a lag in getting the container on the screen.
				view.dispatchEvent(renderEvent());
			});
		
		const mapUpdates:Function = distribute(
			pull(values, 'toString'),
			pull(values, 'html'),
			pull(values, 'width'),
			pull(values, 'cache')
		);
		
		const rendered:ISubject = new BehaviorSubject();
		
		values.combine('html', 'width').
			merge(values.observe('*')).
			map(mapUpdates).
			distinctUntilChanged(nodeIsTheSame).
			map(tail).
			switchMany(apply(function(node:XML, width:Number, cache:Virtualizer):IObservable {
				// TODO: some paragraphs have block-level child elements?
				return span(renderInline, values).take(1).mappend(K(width));
			})).
			mappend(aritize(block, 2)).
			switchMany(apply(function(values:Values, content:ContentElement, width:Number, textBlock:TextBlock):IObservable {
				if(content.rawText == '') return finished;
				
				TextLines.checkIn.apply(null, view['children']);
				
				view.removeChildren();
				
				return lines(width, textBlock).
					peek(ifElse(
						not(view.contains),
						sequence(view.addChild),//, updateEvent, view.dispatchEvent),
						noop
					)).
					ignoreValues().
					concat(finished);
			})).
			multicast(rendered).
			connect();
		
		return rendered;
	}
}
import flash.text.engine.ContentElement;
import flash.text.engine.TextBlock;

import org.tinytlf.fn.setupTextBlock;
import org.tinytlf.observables.Values;
import org.tinytlf.pools.TextBlocks;

internal function nodeIsTheSame(a:Array, b:Array):Boolean {
	// If either is null, do an update.
	if(!a || !b) return false;
	
	const oldToString:String = a[0];
	const newToString:String = b[0];
	
	// If the styles changed, do an update.
	if(oldToString != newToString) return false;
	
	const oldnode:XML = a[1];
	const newnode:XML = b[1];
	
	// If the nodes changed, do an update.
	if(oldnode != newnode) return false;
	
	const oldWidth:Number = a[2];
	const newWidth:Number = b[2];
	
	// If the widths changed, do an update.
	return oldWidth == newWidth;
};


internal function block(values:Values, content:ContentElement):TextBlock {
	return setupTextBlock(TextBlocks.checkOut(), content, values);
};

