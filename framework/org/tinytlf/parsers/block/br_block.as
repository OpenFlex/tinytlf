package org.tinytlf.parsers.block
{
	import flash.display.Shape;
	
	import org.tinytlf.observables.Values;
	
	import raix.reactive.IObservable;
	import raix.reactive.ISubject;
	import raix.reactive.subjects.BehaviorSubject;

	/**
	 * @author ptaylor
	 */
	public function br_block(element:Values):IObservable {
		
		const rendered:ISubject = new BehaviorSubject();
		
		const ui:Shape = new Shape();
		
		element.combine('*').
			map(function(...args):Array {
				
				ui.graphics.clear();
				ui.graphics.beginFill(0x00, 0);
				ui.graphics.drawRect(0, 0, element.width, 1);
				ui.graphics.endFill();
				
				return [element, ui];
			}).
			subscribeWith(rendered);
		
		return rendered;
	}
}