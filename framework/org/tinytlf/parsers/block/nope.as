package org.tinytlf.parsers.block
{
	import raix.reactive.IObservable;
	import raix.reactive.Observable;

	/**
	 * @author ptaylor
	 */
	public function nope(...args):IObservable {
		return Observable.value([args[args.length - 1], null]);
	}
}