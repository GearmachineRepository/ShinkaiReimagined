--!strict

local State = {}

export type Connection = {
	Disconnect: () -> (),
}

export type Observable<T> = {
	Get: () -> T,
	Set: (Value: T) -> (),
	Subscribe: (Callback: (NewValue: T, OldValue: T) -> ()) -> Connection,
	Destroy: () -> (),
}

function State.Create<T>(InitialValue: T): Observable<T>
	local CurrentValue: T = InitialValue
	local NextSubscriberId = 1
	local SubscriberIds: { [number]: (NewValue: T, OldValue: T) -> () } = {}

	local Observable = {}

	function Observable.Get(): T
		return CurrentValue
	end

	function Observable.Set(Value: T)
		if CurrentValue == Value then
			return
		end

		local OldValue = CurrentValue
		CurrentValue = Value

		for _, Callback in SubscriberIds do
			task.spawn(Callback, Value, OldValue)
		end
	end

	function Observable.Subscribe(Callback: (NewValue: T, OldValue: T) -> ()): Connection
		local SubscriberId = NextSubscriberId
		NextSubscriberId = NextSubscriberId + 1
		SubscriberIds[SubscriberId] = Callback

		return {
			Disconnect = function()
				SubscriberIds[SubscriberId] = nil
			end,
		}
	end

	function Observable.Destroy()
		table.clear(SubscriberIds)
	end

	return Observable
end

export type ComputedObservable<T> = {
	Get: () -> T,
	Subscribe: (Callback: (NewValue: T, OldValue: T) -> ()) -> Connection,
	Destroy: () -> (),
}

function State.Computed<T>(Compute: () -> T, Dependencies: { Observable<any> }): ComputedObservable<T>
	local CachedValue: T = Compute()
	local Subscribers: { [number]: (NewValue: T, OldValue: T) -> () } = {}
	local NextSubscriberId = 1
	local DependencyConnections: { Connection } = {}

	local function Recompute()
		local OldValue = CachedValue
		local NewValue = Compute()

		if NewValue == OldValue then
			return
		end

		CachedValue = NewValue

		for _, Callback in Subscribers do
			task.spawn(Callback, NewValue, OldValue)
		end
	end

	for _, Dependency in Dependencies do
		local DependencyConnection = Dependency.Subscribe(function()
			Recompute()
		end)
		table.insert(DependencyConnections, DependencyConnection)
	end

	local Computed = {}

	function Computed.Get(): T
		return CachedValue
	end

	function Computed.Subscribe(Callback: (NewValue: T, OldValue: T) -> ()): Connection
		local SubscriberId = NextSubscriberId
		NextSubscriberId = NextSubscriberId + 1
		Subscribers[SubscriberId] = Callback

		return {
			Disconnect = function()
				Subscribers[SubscriberId] = nil
			end,
		}
	end

	function Computed.Destroy()
		for _, DependencyConnection in DependencyConnections do
			DependencyConnection.Disconnect()
		end
		table.clear(DependencyConnections)
		table.clear(Subscribers)
	end

	return Computed
end

export type ObservableMap<K, V> = {
	Get: (Key: K) -> V?,
	Set: (Key: K, Value: V?) -> (),
	GetAll: () -> { [K]: V },
	Has: (Key: K) -> boolean,
	Clear: () -> (),
	Subscribe: (Callback: (Key: K, NewValue: V?, OldValue: V?) -> ()) -> Connection,
	Destroy: () -> (),
}

function State.CreateMap<K, V>(): ObservableMap<K, V>
	local Data: { [K]: V } = {}
	local Subscribers: { [number]: (Key: K, NewValue: V?, OldValue: V?) -> () } = {}
	local NextSubscriberId = 1

	local Map = {}

	function Map.Get(Key: K): V?
		return Data[Key]
	end

	function Map.Set(Key: K, Value: V?)
		local OldValue = Data[Key]

		if OldValue == Value then
			return
		end

		Data[Key] = Value :: any

		for _, Callback in Subscribers do
			task.spawn(Callback, Key, Value, OldValue)
		end
	end

	function Map.GetAll(): { [K]: V }
		return table.clone(Data)
	end

	function Map.Has(Key: K): boolean
		return Data[Key] ~= nil
	end

	function Map.Clear()
		for Key, _ in Data do
			Map.Set(Key, nil)
		end
	end

	function Map.Subscribe(Callback: (Key: K, NewValue: V?, OldValue: V?) -> ()): Connection
		local SubscriberId = NextSubscriberId
		NextSubscriberId = NextSubscriberId + 1
		Subscribers[SubscriberId] = Callback

		return {
			Disconnect = function()
				Subscribers[SubscriberId] = nil
			end,
		}
	end

	function Map.Destroy()
		table.clear(Data)
		table.clear(Subscribers)
	end

	return Map
end

return State