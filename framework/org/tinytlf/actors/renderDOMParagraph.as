package org.tinytlf.actors
{
	import asx.array.first;
	import asx.array.last;
	import asx.fn.*;
	
	import flash.display.DisplayObjectContainer;
	import flash.text.engine.TextLine;
	
	import org.tinytlf.events.renderEvent;
	import org.tinytlf.handlers.executeThenCancel;
	import org.tinytlf.lambdas.toStyleable;
	import org.tinytlf.types.DOMElement;
	import org.tinytlf.types.Region;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function renderDOMParagraph(region:Region,
									   updates:DOMElement/*<XML>*/,
									   uiFactory:Function/*<String>:<Function<Region>:<DisplayObjectContainer>>*/,
									   childFactory:Function,
									   styles:IObservable/*<CSS>*/):IObservable/*<Rendered>*/ {
		
		const ui:DisplayObjectContainer = uiFactory(updates.key)(region);
		ui.name = updates.key;
		
		const widths:IObservable = region.widthSubj.asObservable();
		const regionStyleables:IObservable = updates.combineLatest(styles, toStyleable);
		
		const same:IObservable = updates.
			scan(function(list:Array, update:XML):Array {
				return [list.pop(), update];
			}, [null], true).
			filter(function(list:Array):Boolean {
				return first(list) === last(list);
			});
		
		const distinct:IObservable = updates.distinctUntilChanged();
		
		const xmlToContentElements:IObservable /*<IObservable<ContentElement>>*/ = 
			distinct.combineLatest(styles, partial(content, uiFactory));
		
		const contentElementsToTextBlocks:IObservable /*<IObservable<TextBlock>>*/ = 
			xmlToContentElements.map(callProperty('map', distribute(block)));
		
		const textBlocksWithWidths:IObservable /*<IObservable<Array<TextBlock, Rectangle>>>*/ = 
			contentElementsToTextBlocks.map(sequence(
				callProperty('combineLatest', widths, args),
				callProperty('peek', aritize(ui.removeChildren, 0))
			));
		
		const textBlocksToTextLines:IObservable = /*<IObservable<IObservable<TextLine>>>*/
			textBlocksWithWidths.map(callProperty('map', sequence(
					distribute(lines),
					callProperty('peek', ui.addChild),
					callProperty('publish'),
					callProperty('refCount')
			)));
		
		const linesHaveRendered:IObservable = textBlocksToTextLines.
			switchMany(callProperty('switchMany', callProperty('count')));
		
		const readyToRender:IObservable = same.merge(linesHaveRendered);//.peek(printNext(updates.key + ' have rendered'));
		
		const subscriptions:CompositeCancelable = new CompositeCancelable([
			
			// Apply styles to the region
			regionStyleables.subscribe(region.mergeWith),
			
			// Dispatch the "render" event on the container UI
			readyToRender.subscribe(sequence(renderEvent, ui.dispatchEvent))
		]);
		
		subscriptions.add(updates.subscribe(
			noop,
			executeThenCancel(subscriptions)(noop),
			executeThenCancel(subscriptions)(noop)
		));
		
		return correlateUpdatesAndRenderedEvents(distinct, updates, widths, ui);
	}
}

import asx.array.first;
import asx.array.head;
import asx.array.map;
import asx.fn.*;
import asx.object.newInstance_;

import flash.display.DisplayObjectContainer;
import flash.text.engine.*;

import org.tinytlf.enumerables.*;
import org.tinytlf.lambdas.*;
import org.tinytlf.pools.*;
import org.tinytlf.procedures.*;
import org.tinytlf.types.*;

import raix.reactive.*;
import raix.reactive.scheduling.Scheduler;

internal function content(uiFactory:Function, node:XML, css:CSS):IObservable {
	
	const styles:Styleable = toStyleable(node, css);
	const name:String = node.localName();
	const numChildren:int = node.*.length();
	
	if(numChildren == 0) {
		const element:ContentElement = (
			aritize(uiFactory(name), 2)(node, styles) ||
			new TextElement(node.toString(), toElementFormat(styles))
		);
		
		return Observable.value([element, node, styles]);
	}
	
	const childObservables:Array = childrenOfXML(node).
		map(partial(content, uiFactory, _, css)).
		map(callProperty('map', first)).
		toArray();
	
	return (
		childObservables.length == 1 ? 
		head(childObservables).map(partial(newInstance_, Array)) :
		Observable.forkJoin(childObservables)
	).
		map(function(elements:Array):Vector.<ContentElement>{
			return Vector.<ContentElement>(elements);
		}).
		map(sequence(
			partial(newInstance_, GroupElement, _, toElementFormat(styles)),
			partial(newInstance_, Array, _, node, styles)
		));
};

internal function block(element:ContentElement, node:XML, styles:Styleable):Array {
	
	const block:TextBlock = setupTextBlock(TextBlocks.checkOut(), element, styles);
	
	return [block, node, styles];
};

internal function lines(block:TextBlock, node:XML, styles:Styleable, width:Number):IObservable {
	
	width -= (styles.getStyle('paddingLeft') || 0);
	width -= (styles.getStyle('paddingRight') || 0);
	
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
		TextLines.checkIn.apply(null, getInvalidLines(block));
		
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
