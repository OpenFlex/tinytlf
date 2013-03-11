package org.tinytlf.streams
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.text.engine.ContentElement;
	
	import asx.fn.args;
	import asx.fn.distribute;
	import asx.fn.partial;
	
	import org.tinytlf.types.CSS;
	import org.tinytlf.types.Region;
	import org.tinytlf.types.Renderable;
	import org.tinytlf.types.Rendered;
	
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.Observable;
	import raix.reactive.Subject;

	/**
	 * @author ptaylor
	 */
	public function mapParagraphRenderable(parent:Region,
										   uiFactory:Function/*(String):Function(Region):DisplayObjectContainer*/,
										   childFactory:Function/*(String):Function(Region, Function, Function, IObservable<CSS>, IGroupedObservable<Renderable>):IObservable<Rendered>*/,
										   styles:IObservable/*<CSS>*/,
										   lifetime:IGroupedObservable/*<Renderable>*/):IObservable/*<Rendered>*/ {
		
		const source:ISubject = new Subject();
		const region:Region = new Region(parent.vScroll, parent.hScroll);
		region.width = parent.width;
		region.height = parent.height;
		
		const ui:DisplayObjectContainer = uiFactory(lifetime.key, region);
		
		var subscription:ICancelable = Cancelable.empty;
		
		return lifetime.combineLatest(region.widthSubj, args).
			switchMany(distribute(function(renderable:Renderable, width:Number):IObservable {
				const node:XML = renderable.node;
				const rendered:ISubject = renderable.rendered;
				
				subscription.cancel();
				ui.removeChildren();
				
				const paragraph:IObservable = styles.take(1).
					mapMany(function(css:CSS):IObservable {
						return content(uiFactory, node, css).
							takeLast(1).
							map(function(element:ContentElement):Array {
								return [element, css];
							});
					}).
					map(distribute(partial(block, node))).
					mapMany(distribute(partial(lines, node, width))).
					publish().
					refCount();
				
				subscription = paragraph.subscribe(ui.addChild);
				
				const container:IObservable = Observable.value(new Rendered(node, ui)).
					peek(function(rendered:Rendered):void {
						ui.dispatchEvent(new Event('render'));
					});
				
				return Observable.concat([paragraph, container]).
					finallyAction(rendered.onCompleted).
					takeLast(1);
			})).
			finallyAction(subscription.cancel);
	}
}
import flash.text.engine.ContentElement;
import flash.text.engine.GroupElement;
import flash.text.engine.TextBlock;
import flash.text.engine.TextElement;
import flash.text.engine.TextLine;

import asx.fn.I;
import asx.fn.guard;
import asx.fn.partial;

import org.tinytlf.lambdas.createTextLine;
import org.tinytlf.lambdas.getInvalidLines;
import org.tinytlf.lambdas.getLineBeforeFirstInvalidLine;
import org.tinytlf.lambdas.getValidLines;
import org.tinytlf.lambdas.isBlockInvalid;
import org.tinytlf.lambdas.setupTextBlock;
import org.tinytlf.lambdas.toElementFormat;
import org.tinytlf.lambdas.toStyleable;
import org.tinytlf.pools.TextBlocks;
import org.tinytlf.pools.TextLines;
import org.tinytlf.procedures.applyNodeInheritance;
import org.tinytlf.streams.iterateXMLChildren;
import org.tinytlf.types.CSS;
import org.tinytlf.types.Styleable;

import raix.reactive.IObservable;
import raix.reactive.Observable;

internal function content(uiFactory:Function/*(String):Function(XML):ContentElement*/,
						  node:XML,
						  css:CSS):IObservable {
	
	node = applyNodeInheritance(node);
	const name:String = node.localName();
	const numChildren:int = node.*.length();
	const styles:Styleable = toStyleable(node, css);
	
	if(numChildren == 0) {
		const element:ContentElement = guard(uiFactory(name))(node, styles) ||
			new TextElement(node.toString(), toElementFormat(styles));
		return Observable.value(element);
	}
	
	return iterateXMLChildren(node).
		map(applyNodeInheritance).
		concatMany(partial(content, css, uiFactory)).
		bufferWithCount(numChildren).
		map(function(elements:Array):ContentElement {
			return new GroupElement(Vector.<ContentElement>(elements), toElementFormat(styles));
		});
}

internal function block(node:XML, element:ContentElement, css:CSS):Array {
	return [setupTextBlock(TextBlocks.checkOut(), element, toStyleable(node, css)), css];
}

internal function lines(node:XML, width:Number, block:TextBlock, css:CSS):IObservable {
	const styles:Styleable = toStyleable(node, css);
	
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
	return Observable.generate(iterate(null), predicate, iterate, I);
}
