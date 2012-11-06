package org.tinytlf.streams
{
	import raix.reactive.IObservable;

	public interface IStream
	{
		function get observable():IObservable;
	}
}