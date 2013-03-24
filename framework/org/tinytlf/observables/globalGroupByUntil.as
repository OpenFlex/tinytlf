package org.tinytlf.observables {
	import asx.fn.I;
	
	import raix.reactive.CompositeCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.IGroupedObservable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.ISubject;
	import raix.reactive.MutableCancelable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.scheduling.Scheduler;
	
	/**
	 * @author ptaylor
	 */
	public function globalGroupByUntil(source:IObservable,
									   keySelector:Function,
									   durationSelector:Function,
									   elementSelector:Function = null,
									   keyComparer:Function = null):IObservable {
		
		var defaultComparer:Function = function(a:Object, b:Object):Boolean {
			return a == b;
		}
		
		keyComparer = (keyComparer == null)
			? defaultComparer
			: normalizeComparer(keyComparer);
		
		elementSelector = (elementSelector == null) ? I : elementSelector;
		
		return Observable.createWithCancelable(function(observer:IObserver):ICancelable
		{
			var onError:Function = function(error:Error):void
			{
				for each (var activeGroupSubject:ISubject in activeGroupSubjects)
				{
					activeGroupSubject.onError(error);
				}
				
				observer.onError(error);
			};
			
			var findKey:Function = function(key:Object):int
			{
				for (var i:int = 0; i < activeGroupKeys.length; i++)
				{
					if (keyComparer(activeGroupKeys[i], key))
					{
						return i;
					}
				}
				
				return -1;
			};
			
			var sourceSubscription:MutableCancelable = new MutableCancelable();
			
			sourceSubscription.cancelable = source.subscribe(
				function(sourceValue:Object):void
				{
					var key:Object;
					var element:Object;
					var keyIndex:int = -1;
					
					try
					{
						key = keySelector(sourceValue);
						element = elementSelector(sourceValue);
						
						keyIndex = findKey(key);
					}
					catch (error:Error)
					{
						onError(error);
						return;
					}
					
					var groupSubject:Subject = null;
					
					if (keyIndex != -1)
					{
						groupSubject = activeGroupSubjects[keyIndex] as Subject;
						
						groupSubject.onNext(element);
					}
					else
					{
						groupSubject = new Subject();
						
						activeGroupKeys.push(key);
						activeGroupSubjects.push(groupSubject);
						
						var group:IGroupedObservable = new GroupedObservable(key, groupSubject);
						
						var groupDuration:IObservable;
						
						try
						{
							groupDuration = IObservable(durationSelector(group));
						}
						catch (error:Error)
						{
							onError(error);
							return;
						}
						
						observer.onNext(group);
						
						// Dispatch the element on the Scheduler, because
						// observers may have been added to the group that
						// are awaiting subscription in the Scheduler queue.
						Scheduler.immediate.schedule(function():void {
							groupSubject.onNext(element);
						}, 1);
						
						groupDuration.take(1).subscribe(null, function():void {
							var keyIndex:int = -1;
							
							try
							{
								keyIndex = findKey(key);
							}
							catch (error:Error)
							{
								onError(error);
								return;
							}
							
							groupSubject.onCompleted();
							activeGroupKeys.splice(keyIndex, 1);
							activeGroupSubjects.splice(keyIndex, 1);
						});
					}
				}, observer.onCompleted, onError);
			
			return new CompositeCancelable([sourceSubscription]);
		});
	}
}

internal var activeGroupKeys:Array = new Array();
internal var activeGroupSubjects:Array = new Array();

internal function normalizeComparer(source:Function):Function {
	return function(a:Object, b:Object):Boolean
	{
		var result:Object = source(a, b);
		
		if (result is Boolean)
		{
			return (result == true);
		}
		
		if (result is int || result is Number || result is uint)
		{
			return (result == 0);
		}
		
		throw new ArgumentError("comparer function must return Boolean or int");
	};
}