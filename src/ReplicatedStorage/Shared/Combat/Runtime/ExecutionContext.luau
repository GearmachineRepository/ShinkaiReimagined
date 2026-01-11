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
type ExecutionContext = ActionTypes.ExecutionContext
type SignalState = ActionTypes.SignalState
type EventBus = ActionTypes.EventBus

local ExecutionContextModule = {}

local DEFAULT_PROPERTIES = table.freeze({
	DamageMultiplier = 1,
	KnockbackMultiplier = 1,
	Invincible = false,
}) :: ActionProperties

function ExecutionContextModule.Create(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ExecutionContext
	local StartTime = tick()

	local Properties: any = TableUtil.Copy(DEFAULT_PROPERTIES)
	if ActionDefinition.Properties then
		Properties = TableUtil.Assign(Properties, ActionDefinition.Properties)
	end

	local HitRecords: { HitRecord } = {}
	local LastHitTarget: Model? = nil
	local Canceled = false

	local Signals: SignalState = {
		Active = {},
		Expiry = {},
		Counters = {},
	}

	local function GetElapsedTime(): number
		return tick() - StartTime
	end

	local function Cancel()
		Canceled = true
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
		local Result = {}
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

	local Context: ExecutionContext = {
		Entity = Entity,
		ActionDefinition = ActionDefinition,
		EventBus = EventBus,
		StartTime = StartTime,
		Canceled = Canceled,
		Properties = Properties,
		HitRecords = HitRecords,
		LastHitTarget = LastHitTarget,
		Signals = Signals,

		GetElapsedTime = GetElapsedTime,
		Cancel = Cancel,
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
	}

	return setmetatable({}, {
		__index = function(_, Key)
			if Key == "Canceled" then
				return Canceled
			elseif Key == "HitRecords" then
				return HitRecords :: any
			elseif Key == "LastHitTarget" then
				return LastHitTarget :: any
			elseif Key == "Signals" then
				return Signals :: any
			else
				return (Context :: any)[Key]
			end
		end,
		__newindex = function(_, Key, Value)
			if Key == "Canceled" then
				Canceled = Value
			end
		end,
	}) :: any
end

return ExecutionContextModule