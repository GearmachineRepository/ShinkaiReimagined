--!strict

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ValueEvaluator = {}

export type EvaluationContext = {
	Entity: any,
	LastHitTarget: Model?,
	Tags: { [string]: boolean },
	IsSignalActive: ((SignalId: string) -> boolean)?,
	ResolveInput: (PropertyKey: string) -> any,
	Targets: { Model }?,
}

export type EvaluationResult = { [string]: any }

local IsServer = RunService:IsServer()

local Evaluators: { [string]: (Context: EvaluationContext, Properties: { [string]: any }) -> EvaluationResult } = {}

local function GetHumanoidRootPart(Character: Model): BasePart?
	return Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function GetHumanoid(Character: Model): Humanoid?
	return Character:FindFirstChildOfClass("Humanoid")
end

local function GetEnsemble(): any?
	if not IsServer then
		return nil
	end
	local Server = ServerScriptService:FindFirstChild("Server")
	if not Server then
		return nil
	end
	local EnsembleModule = Server:FindFirstChild("Ensemble")
	return EnsembleModule and require(EnsembleModule)
end

local function GetStatComponent(): any?
	if not IsServer then
		return nil
	end
	local Server = ServerScriptService:FindFirstChild("Server")
	if not Server then
		return nil
	end
	local Components = Server:FindFirstChild("Components")
	if not Components then
		return nil
	end
	local StatComp = Components:FindFirstChild("StatComponent")
	return StatComp and require(StatComp)
end

local function GetStateComponent(): any?
	if not IsServer then
		return nil
	end
	local Server = ServerScriptService:FindFirstChild("Server")
	if not Server then
		return nil
	end
	local Components = Server:FindFirstChild("Components")
	if not Components then
		return nil
	end
	local StateComp = Components:FindFirstChild("StateComponent")
	return StateComp and require(StateComp)
end

local function ResolveTargetCharacter(Context: EvaluationContext, TargetMode: string): Model?
	if TargetMode == "Self" then
		return Context.Entity and Context.Entity.Character
	elseif TargetMode == "LastHit" then
		return Context.LastHitTarget
	end
	return nil
end

local function ToNumber(Value: any): number
	if type(Value) == "number" then
		return Value
	elseif type(Value) == "boolean" then
		return if Value then 1 else 0
	elseif type(Value) == "string" then
		return tonumber(Value) or 0
	end
	return 0
end

local function ToBoolean(Value: any): boolean
	if type(Value) == "boolean" then
		return Value
	elseif type(Value) == "number" then
		return Value ~= 0
	elseif type(Value) == "string" then
		return Value ~= ""
	end
	return Value ~= nil
end

local function ResolveNumber(Context: EvaluationContext, Key: string, Properties: { [string]: any }, Default: number): number
	local Value = Context.ResolveInput(Key)
	if Value ~= nil then
		return ToNumber(Value)
	end
	return ToNumber(Properties[Key] or Default)
end

local function ResolveBoolean(Context: EvaluationContext, Key: string, Properties: { [string]: any }, Default: boolean): boolean
	local Value = Context.ResolveInput(Key)
	if Value ~= nil then
		return ToBoolean(Value)
	end
	local PropValue = Properties[Key]
	if PropValue ~= nil then
		return ToBoolean(PropValue)
	end
	return Default
end

Evaluators.Constant = function(_Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueType = Properties.Type or "Number"

	if ValueType == "Number" then
		return { Value = Properties.NumberValue or 0 }
	elseif ValueType == "Boolean" then
		return { Value = Properties.BooleanValue or false }
	elseif ValueType == "String" then
		return { Value = Properties.StringValue or "" }
	end

	return { Value = Properties.NumberValue or 0 }
end

Evaluators.Compare = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = ResolveNumber(Context, "A", Properties, 0)
	local ValueB = ResolveNumber(Context, "B", Properties, 0)
	local Operator = Properties.Operator or ">"

	local Operations: { [string]: () -> boolean } = {
		[">"] = function() return ValueA > ValueB end,
		["<"] = function() return ValueA < ValueB end,
		[">="] = function() return ValueA >= ValueB end,
		["<="] = function() return ValueA <= ValueB end,
		["=="] = function() return ValueA == ValueB end,
		["!="] = function() return ValueA ~= ValueB end,
	}

	local Operation = Operations[Operator]
	return { Result = Operation and Operation() or false }
end

Evaluators.Math = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = ResolveNumber(Context, "A", Properties, 0)
	local ValueB = ResolveNumber(Context, "B", Properties, 0)
	local Operator = Properties.Operator or "+"

	local Operations: { [string]: () -> number } = {
		["+"] = function() return ValueA + ValueB end,
		["-"] = function() return ValueA - ValueB end,
		["*"] = function() return ValueA * ValueB end,
		["/"] = function() return if ValueB ~= 0 then ValueA / ValueB else 0 end,
		["%"] = function() return if ValueB ~= 0 then ValueA % ValueB else 0 end,
		["^"] = function() return ValueA ^ ValueB end,
		["min"] = function() return math.min(ValueA, ValueB) end,
		["max"] = function() return math.max(ValueA, ValueB) end,
	}

	local Operation = Operations[Operator]
	return { Result = Operation and Operation() or 0 }
end

Evaluators.Random = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Min = ResolveNumber(Context, "Min", Properties, 0)
	local Max = ResolveNumber(Context, "Max", Properties, 1)
	local IsInteger = Properties.Integer or false

	if Min > Max then
		Min, Max = Max, Min
	end

	local Result: number
	if IsInteger then
		Result = math.random(math.floor(Min), math.floor(Max))
	else
		Result = Min + math.random() * (Max - Min)
	end

	return { Result = Result }
end

Evaluators.Clamp = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = ResolveNumber(Context, "Value", Properties, 0)
	local Min = ResolveNumber(Context, "Min", Properties, 0)
	local Max = ResolveNumber(Context, "Max", Properties, 1)

	return { Result = math.clamp(Value, Min, Max) }
end

Evaluators.Lerp = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local A = ResolveNumber(Context, "A", Properties, 0)
	local B = ResolveNumber(Context, "B", Properties, 1)
	local Alpha = ResolveNumber(Context, "Alpha", Properties, 0.5)

	return { Result = A + (B - A) * Alpha }
end

Evaluators.Select = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Condition = ResolveBoolean(Context, "Condition", Properties, true)
	local TrueValue = Context.ResolveInput("True") or Properties.TrueValue or 1
	local FalseValue = Context.ResolveInput("False") or Properties.FalseValue or 0

	return { Result = if Condition then TrueValue else FalseValue }
end

Evaluators.And = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = ResolveBoolean(Context, "A", Properties, false)
	local ValueB = ResolveBoolean(Context, "B", Properties, false)
	return { Result = ValueA and ValueB }
end

Evaluators.Or = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = ResolveBoolean(Context, "A", Properties, false)
	local ValueB = ResolveBoolean(Context, "B", Properties, false)
	return { Result = ValueA or ValueB }
end

Evaluators.Not = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = ResolveBoolean(Context, "Value", Properties, false)
	return { Result = not Value }
end

Evaluators.SignalActive = function(Context: EvaluationContext, _Properties: { [string]: any }): EvaluationResult
	return { Active = Context.IsSignalActive ~= nil }
end

Evaluators.Self = function(Context: EvaluationContext, _Properties: { [string]: any }): EvaluationResult
	return { Entity = Context.Entity }
end

Evaluators.LastHitTarget = function(Context: EvaluationContext, _Properties: { [string]: any }): EvaluationResult
	return {
		Entity = Context.LastHitTarget,
		Valid = Context.LastHitTarget ~= nil,
	}
end

Evaluators.GetHealth = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local TargetMode = Properties.Target or "Self"
	local TargetCharacter = ResolveTargetCharacter(Context, TargetMode)

	if not TargetCharacter then
		return { Current = 0, Max = 0, Percent = 0 }
	end

	local TargetHumanoid = GetHumanoid(TargetCharacter)
	if not TargetHumanoid then
		return { Current = 0, Max = 0, Percent = 0 }
	end

	local Current = TargetHumanoid.Health
	local Max = TargetHumanoid.MaxHealth
	local Percent = if Max > 0 then (Current / Max) * 100 else 0

	return {
		Current = Current,
		Max = Max,
		Percent = Percent,
	}
end

Evaluators.GetStat = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local TargetMode = Properties.TargetMode or "Self"
	local StatName = Properties.Stat or "Health"

	local TargetCharacter = ResolveTargetCharacter(Context, TargetMode)
	if not TargetCharacter then
		return { Value = 0 }
	end

	local Ensemble = GetEnsemble()
	local StatComponent = GetStatComponent()
	if not Ensemble or not StatComponent then
		return { Value = 0 }
	end

	local Entity = Ensemble.GetEntity(TargetCharacter)
	if not Entity then
		return { Value = 0 }
	end

	local Stats = StatComponent.From(Entity)
	if not Stats then
		return { Value = 0 }
	end

	return { Value = Stats.GetStat(StatName) }
end

Evaluators.GetState = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local TargetMode = Properties.TargetMode or "Self"
	local StateName = Properties.State or "Blocking"

	local TargetCharacter = ResolveTargetCharacter(Context, TargetMode)
	if not TargetCharacter then
		return { Active = false }
	end

	local Ensemble = GetEnsemble()
	local StateComponent = GetStateComponent()
	if not Ensemble or not StateComponent then
		return { Active = false }
	end

	local Entity = Ensemble.GetEntity(TargetCharacter)
	if not Entity then
		return { Active = false }
	end

	local States = StateComponent.From(Entity)
	if not States then
		return { Active = false }
	end

	return { Active = States.GetState(StateName) }
end

Evaluators.GetDistance = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local FromMode = Properties.From or "Self"
	local ToMode = Properties.To or "LastHit"

	local FromCharacter = ResolveTargetCharacter(Context, FromMode)
	local ToCharacter = ResolveTargetCharacter(Context, ToMode)

	if not FromCharacter or not ToCharacter then
		return { Distance = math.huge }
	end

	local FromRoot = GetHumanoidRootPart(FromCharacter)
	local ToRoot = GetHumanoidRootPart(ToCharacter)

	if not FromRoot or not ToRoot then
		return { Distance = math.huge }
	end

	return { Distance = (FromRoot.Position - ToRoot.Position).Magnitude }
end

Evaluators.GetTag = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local TagName = Properties.Tag or ""
	local TagValue = Context.Tags and Context.Tags[TagName] or false
	return { Value = TagValue }
end

Evaluators.SelectTarget = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Targets = Context.Targets or {}
	local Criteria = Properties.Criteria or "Nearest"

	if #Targets == 0 then
		return { Target = nil, Found = false }
	end

	local SelfCharacter = Context.Entity and Context.Entity.Character
	local SelfRoot = SelfCharacter and GetHumanoidRootPart(SelfCharacter)

	local SelectedTarget: Model? = nil

	local function SelectByDistance(SelectNearest: boolean): Model?
		if not SelfRoot then
			return nil
		end

		local BestDistance: number = if SelectNearest then math.huge else 0
		local BestTarget: Model? = nil

		for _, TargetModel: Model in ipairs(Targets) do
			local TargetRoot: BasePart? = GetHumanoidRootPart(TargetModel)
			if TargetRoot then
				local Distance: number = (SelfRoot.Position - TargetRoot.Position).Magnitude
				local IsBetter: boolean = if SelectNearest then (Distance < BestDistance) else (Distance > BestDistance)

				if IsBetter then
					BestDistance = Distance
					BestTarget = TargetModel
				end
			end
		end

		return BestTarget
	end

	local function SelectByHealth(SelectLowest: boolean): Model?
		local BestHealth: number = if SelectLowest then math.huge else 0
		local BestTarget: Model? = nil

		for _, TargetModel: Model in ipairs(Targets) do
			local TargetHumanoid: Humanoid? = GetHumanoid(TargetModel)
			if TargetHumanoid then
				local Health: number = TargetHumanoid.Health
				local IsBetter: boolean = if SelectLowest then (Health < BestHealth) else (Health > BestHealth)

				if IsBetter then
					BestHealth = Health
					BestTarget = TargetModel
				end
			end
		end

		return BestTarget
	end

	if Criteria == "Random" then
		SelectedTarget = Targets[math.random(1, #Targets)]
	elseif Criteria == "Nearest" then
		SelectedTarget = SelectByDistance(true)
	elseif Criteria == "Farthest" then
		SelectedTarget = SelectByDistance(false)
	elseif Criteria == "LowestHealth" then
		SelectedTarget = SelectByHealth(true)
	elseif Criteria == "HighestHealth" then
		SelectedTarget = SelectByHealth(false)
	else
		SelectedTarget = Targets[1]
	end

	return {
		Target = SelectedTarget,
		Found = SelectedTarget ~= nil,
	}
end

function ValueEvaluator.Evaluate(
	BlockType: string,
	Context: EvaluationContext,
	Properties: { [string]: any }
): EvaluationResult?
	local Evaluator = Evaluators[BlockType]
	if not Evaluator then
		return nil
	end

	local Success, Result = pcall(Evaluator, Context, Properties)
	if not Success then
		warn(string.format("[ValueEvaluator] Error evaluating %s: %s", BlockType, tostring(Result)))
		return nil
	end

	return Result
end

function ValueEvaluator.Has(BlockType: string): boolean
	return Evaluators[BlockType] ~= nil
end

function ValueEvaluator.Register(BlockType: string, Evaluator: (Context: EvaluationContext, Properties: { [string]: any }) -> EvaluationResult)
	Evaluators[BlockType] = Evaluator
end

function ValueEvaluator.GetAll(): { string }
	local Types: { string } = {}
	for BlockType in Evaluators do
		table.insert(Types, BlockType)
	end
	table.sort(Types)
	return Types
end

function ValueEvaluator.ToNumber(Value: any): number
	return ToNumber(Value)
end

function ValueEvaluator.ToBoolean(Value: any): boolean
	return ToBoolean(Value)
end

return ValueEvaluator