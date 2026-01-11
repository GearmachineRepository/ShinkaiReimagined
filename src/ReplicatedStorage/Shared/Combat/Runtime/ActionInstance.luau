--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local ActionTypes = require(Shared.Types.ActionTypes)

local TableUtil = Packages.TableUtil

type ExecutionEntity = ActionTypes.ExecutionEntity
type ActionDefinition = ActionTypes.ActionDefinition
type ActionProperties = ActionTypes.ActionProperties
type HitRecord = ActionTypes.HitRecord
type SignalState = ActionTypes.SignalState

local ActionInstance = {}

export type ValueCache = { [string]: any }

export type ChannelOwnership = {
	Channel: string,
	Priority: number,
	AcquiredAt: number,
}

export type ActionInstanceState = "Pending" | "Running" | "Completed" | "Canceled"

export type ActionInstanceHandle = {
	InstanceId: string,
	ActionId: string,
	State: ActionInstanceState,
	Entity: ExecutionEntity,
	EventBus: any,
	CompiledGraph: any,
	CurrentBranchName: string?,
	Properties: ActionProperties,
	StartTime: number,
	Canceled: boolean,
	HitRecords: { HitRecord },
	LastHitTarget: Model?,
	Signals: SignalState,
	ValueCache: ValueCache,
	ChannelOwnership: { ChannelOwnership },
	Tags: { [string]: boolean },

	GetElapsedTime: () -> number,
	Cancel: () -> (),
	IsCanceled: () -> boolean,
	SetState: (NewState: ActionInstanceState) -> (),
	GetState: () -> ActionInstanceState,

	RecordHit: (Target: Model, Damage: number) -> (),
	HadHitInWindow: (WindowSeconds: number) -> boolean,
	GetLastHitTarget: () -> Model?,

	EmitSignal: (SignalId: string, Duration: number?) -> (),
	ClearSignal: (SignalId: string) -> (),
	IsSignalActive: (SignalId: string) -> boolean,
	GetActiveSignals: () -> { string },

	IncrementCounter: (CounterId: string) -> number,
	GetCounter: (CounterId: string) -> number,
	ResetCounter: (CounterId: string) -> (),

	ResolveValue: (NodeId: string, PropertyName: string) -> any,
	CacheValue: (NodeId: string, PortName: string, Value: any) -> (),
	GetCachedValue: (NodeId: string, PortName: string) -> any?,
	ClearValueCache: () -> (),

	AcquireChannel: (Channel: string, Priority: number) -> boolean,
	ReleaseChannel: (Channel: string) -> (),
	OwnsChannel: (Channel: string) -> boolean,

	SetTag: (Tag: string, Value: boolean) -> (),
	GetTag: (Tag: string) -> boolean,
	GetAllTags: () -> { [string]: boolean },

	Destroy: () -> (),
}

local DEFAULT_PROPERTIES = table.freeze({
	DamageMultiplier = 1,
	KnockbackMultiplier = 1,
	Invincible = false,
}) :: ActionProperties

local InstanceIdCounter = 0

local function GenerateInstanceId(): string
	InstanceIdCounter = InstanceIdCounter + 1
	return string.format("action_%d_%d", os.clock() * 1000, InstanceIdCounter)
end

function ActionInstance.Create(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	CompiledGraph: any,
	EventBus: any
): ActionInstanceHandle
	local InstanceId = GenerateInstanceId()
	local StartTime = tick()

	local Properties: any = TableUtil.Copy(DEFAULT_PROPERTIES)
	if ActionDefinition.Properties then
		Properties = TableUtil.Assign(Properties, ActionDefinition.Properties)
	end

	local State: ActionInstanceState = "Pending"
	local Canceled = false
	local HitRecords: { HitRecord } = {}
	local LastHitTarget: Model? = nil
	local LocalValueCache: ValueCache = {}
	local ChannelOwnerships: { ChannelOwnership } = {}
	local LocalTags: { [string]: boolean } = {}

	local Signals: SignalState = {
		Active = {},
		Expiry = {},
		Counters = {},
	}

	local CurrentBranchName: string? = nil

	local function GetElapsedTime(): number
		return tick() - StartTime
	end

	local function DoCancel()
		if Canceled then
			return
		end
		Canceled = true
		State = "Canceled"
	end

	local function IsCanceled(): boolean
		return Canceled
	end

	local function SetState(NewState: ActionInstanceState)
		State = NewState
	end

	local function GetState(): ActionInstanceState
		return State
	end

	local function RecordHit(Target: Model, Damage: number)
		local Record: HitRecord = {
			Target = Target,
			Timestamp = tick(),
			Damage = Damage,
		}
		table.insert(HitRecords, Record)
		LastHitTarget = Target
	end

	local function HadHitInWindow(WindowSeconds: number): boolean
		local CutoffTime = tick() - WindowSeconds
		for _, Record in HitRecords do
			if Record.Timestamp >= CutoffTime then
				return true
			end
		end
		return false
	end

	local function GetLastHitTarget(): Model?
		return LastHitTarget
	end

	local function EmitSignal(SignalId: string, Duration: number?)
		Signals.Active[SignalId] = true

		if Duration and Duration > 0 then
			local ExpiryTime = tick() + Duration
			Signals.Expiry[SignalId] = ExpiryTime

			task.delay(Duration, function()
				if Signals.Expiry[SignalId] == ExpiryTime then
					Signals.Active[SignalId] = nil
					Signals.Expiry[SignalId] = nil
				end
			end)
		end
	end

	local function ClearSignal(SignalId: string)
		Signals.Active[SignalId] = nil
		Signals.Expiry[SignalId] = nil
	end

	local function IsSignalActive(SignalId: string): boolean
		if not Signals.Active[SignalId] then
			return false
		end

		local ExpiryTime = Signals.Expiry[SignalId]
		if ExpiryTime and tick() >= ExpiryTime then
			Signals.Active[SignalId] = nil
			Signals.Expiry[SignalId] = nil
			return false
		end

		return true
	end

	local function GetActiveSignals(): { string }
		local Result: { string } = {}
		for SignalId in Signals.Active do
			if IsSignalActive(SignalId) then
				table.insert(Result, SignalId)
			end
		end
		return Result
	end

	local function IncrementCounter(CounterId: string): number
		local Current = Signals.Counters[CounterId] or 0
		Current = Current + 1
		Signals.Counters[CounterId] = Current
		return Current
	end

	local function GetCounter(CounterId: string): number
		return Signals.Counters[CounterId] or 0
	end

	local function ResetCounter(CounterId: string)
		Signals.Counters[CounterId] = nil
	end

	local function CacheValue(NodeId: string, PortName: string, Value: any)
		local CacheKey = NodeId .. ":" .. PortName
		LocalValueCache[CacheKey] = Value
	end

	local function GetCachedValue(NodeId: string, PortName: string): any?
		local CacheKey = NodeId .. ":" .. PortName
		return LocalValueCache[CacheKey]
	end

	local function ClearValueCache()
		table.clear(LocalValueCache)
	end

	local ResolveValue: (NodeId: string, PropertyName: string) -> any

	local function EvaluatePureNode(
		Node: any,
		_Definition: any
	): { [string]: any }?
		local ValueEvaluator = require(script.Parent.Parent.Graph.ValueEvaluator)

		local function ResolveInput(PropertyKey: string): any
			return ResolveValue(Node.NodeId, PropertyKey)
		end

		local EvalContext: ValueEvaluator.EvaluationContext = {
			Entity = Entity,
			LastHitTarget = LastHitTarget,
			Tags = LocalTags,
			IsSignalActive = IsSignalActive,
			ResolveInput = ResolveInput,
		}

		return ValueEvaluator.Evaluate(Node.BlockType, EvalContext, Node.Properties)
	end

	ResolveValue = function(NodeId: string, PropertyName: string): any
		local Cached = GetCachedValue(NodeId, PropertyName)
		if Cached ~= nil then
			return Cached
		end

		local Compiler = require(script.Parent.Parent.Graph.Compiler)
		local BlockDefs = require(script.Parent.Parent.BlockDefinitions)

		local BranchName = CurrentBranchName
		if not BranchName or not CompiledGraph then
			local Branch = Compiler.GetEntryBranch(CompiledGraph)
			if Branch then
				local Node = Branch.Nodes[NodeId]
				if Node then
					return Node.Properties[PropertyName]
				end
			end
			return nil
		end

		local Branch = CompiledGraph.Branches[BranchName]
		if not Branch then
			return nil
		end

		local Node = Branch.Nodes[NodeId]
		if not Node then
			return nil
		end

		local Definition = BlockDefs.Get(Node.BlockType)
		if Definition and Definition.Pure then
			local Result = EvaluatePureNode(Node, Definition)
			if Result ~= nil and Result[PropertyName] ~= nil then
				CacheValue(NodeId, PropertyName, Result[PropertyName])
				return Result[PropertyName]
			end
		end

		local ValueSource = Compiler.GetValueSource(CompiledGraph, BranchName, NodeId, PropertyName)

		if ValueSource then
			local UpstreamValue = ResolveValue(ValueSource.FromNodeId, ValueSource.FromPortName)
			CacheValue(NodeId, PropertyName, UpstreamValue)
			return UpstreamValue
		end

		local PropertyValue = Compiler.GetNodeProperty(CompiledGraph, BranchName, NodeId, PropertyName)
		return PropertyValue
	end

	local function AcquireChannel(Channel: string, Priority: number): boolean
		for _, Ownership in ChannelOwnerships do
			if Ownership.Channel == Channel then
				return true
			end
		end

		table.insert(ChannelOwnerships, {
			Channel = Channel,
			Priority = Priority,
			AcquiredAt = tick(),
		})

		return true
	end

	local function ReleaseChannel(Channel: string)
		for Index, Ownership in ChannelOwnerships do
			if Ownership.Channel == Channel then
				table.remove(ChannelOwnerships, Index)
				return
			end
		end
	end

	local function OwnsChannel(Channel: string): boolean
		for _, Ownership in ChannelOwnerships do
			if Ownership.Channel == Channel then
				return true
			end
		end
		return false
	end

	local function SetTag(Tag: string, Value: boolean)
		LocalTags[Tag] = Value
	end

	local function GetTag(Tag: string): boolean
		return LocalTags[Tag] == true
	end

	local function GetAllTags(): { [string]: boolean }
		return table.clone(LocalTags)
	end

	local function Destroy()
		table.clear(LocalValueCache)
		table.clear(ChannelOwnerships)
		table.clear(LocalTags)
		table.clear(HitRecords)
		table.clear(Signals.Active)
		table.clear(Signals.Expiry)
		table.clear(Signals.Counters)
	end

	local Instance: ActionInstanceHandle = {
		InstanceId = InstanceId,
		ActionId = ActionDefinition.ActionId,
		State = State,
		Entity = Entity,
		EventBus = EventBus,
		CompiledGraph = CompiledGraph,
		CurrentBranchName = CurrentBranchName,
		Properties = Properties,
		StartTime = StartTime,
		Canceled = Canceled,
		HitRecords = HitRecords,
		LastHitTarget = LastHitTarget,
		Signals = Signals,
		ValueCache = LocalValueCache,
		ChannelOwnership = ChannelOwnerships,
		Tags = LocalTags,

		GetElapsedTime = GetElapsedTime,
		Cancel = DoCancel,
		IsCanceled = IsCanceled,
		SetState = SetState,
		GetState = GetState,

		RecordHit = RecordHit,
		HadHitInWindow = HadHitInWindow,
		GetLastHitTarget = GetLastHitTarget,

		EmitSignal = EmitSignal,
		ClearSignal = ClearSignal,
		IsSignalActive = IsSignalActive,
		GetActiveSignals = GetActiveSignals,

		IncrementCounter = IncrementCounter,
		GetCounter = GetCounter,
		ResetCounter = ResetCounter,

		ResolveValue = ResolveValue,
		CacheValue = CacheValue,
		GetCachedValue = GetCachedValue,
		ClearValueCache = ClearValueCache,

		AcquireChannel = AcquireChannel,
		ReleaseChannel = ReleaseChannel,
		OwnsChannel = OwnsChannel,

		SetTag = SetTag,
		GetTag = GetTag,
		GetAllTags = GetAllTags,

		Destroy = Destroy,
	}

	return setmetatable({}, {
		__index = function(_, Key)
			if Key == "State" then
				return State
			elseif Key == "Canceled" then
				return Canceled
			elseif Key == "HitRecords" then
				return HitRecords
			elseif Key == "LastHitTarget" then
				return LastHitTarget
			elseif Key == "Signals" then
				return Signals
			elseif Key == "ValueCache" then
				return LocalValueCache
			elseif Key == "ChannelOwnership" then
				return ChannelOwnerships
			elseif Key == "Tags" then
				return LocalTags
			elseif Key == "CurrentBranchName" then
				return CurrentBranchName
			else
				return (Instance :: any)[Key]
			end
		end,
		__newindex = function(_, Key, Value)
			if Key == "State" then
				State = Value
			elseif Key == "Canceled" then
				Canceled = Value
			elseif Key == "CurrentBranchName" then
				CurrentBranchName = Value
			end
		end,
	}) :: any
end

function ActionInstance.CreateLegacyContext(InstanceHandle: ActionInstanceHandle): ActionTypes.ExecutionContext
	return {
		Entity = InstanceHandle.Entity,
		ActionDefinition = {
			ActionId = InstanceHandle.ActionId,
		} :: any,
		EventBus = InstanceHandle.EventBus,
		StartTime = InstanceHandle.StartTime,
		Canceled = InstanceHandle.Canceled,
		Properties = InstanceHandle.Properties,
		HitRecords = InstanceHandle.HitRecords,
		LastHitTarget = InstanceHandle.LastHitTarget,
		Signals = InstanceHandle.Signals,

		GetElapsedTime = InstanceHandle.GetElapsedTime,
		Cancel = InstanceHandle.Cancel,
		RecordHit = InstanceHandle.RecordHit,
		HadHitInWindow = InstanceHandle.HadHitInWindow,
		GetLastHitTarget = InstanceHandle.GetLastHitTarget,

		EmitSignal = InstanceHandle.EmitSignal,
		ClearSignal = InstanceHandle.ClearSignal,
		IsSignalActive = InstanceHandle.IsSignalActive,
		GetActiveSignals = InstanceHandle.GetActiveSignals,
		IncrementCounter = InstanceHandle.IncrementCounter,
		GetCounter = InstanceHandle.GetCounter,
		ResetCounter = InstanceHandle.ResetCounter,
	}
end

return ActionInstance