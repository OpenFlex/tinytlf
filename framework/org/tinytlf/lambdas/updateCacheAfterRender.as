package org.tinytlf.lambdas
{
	import org.tinytlf.types.Rendered;
	
	import trxcllnt.ds.Envelope;
	import trxcllnt.ds.RTree;

	/**
	 * @author ptaylor
	 */
	public function updateCacheAfterRender(cache:RTree):Function {
		return function(rendered:Rendered):void {
			cache.setSize(rendered.element, new Envelope(rendered.display));
		};
	}
}