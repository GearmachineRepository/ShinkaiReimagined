--!strict

local ValueEvaluator = {}

export type EvaluationContext = {
	Entity: any,
	LastHitTarget: Model?,
	Tags: { [string]: boolean },
	IsSignalActive: ((SignalId: string) -> boolean)?,
	ResolveInput: (PropertyKey: string) -> any,
}

export type EvaluationResult = { [string]: any }

local Evaluators: { [string]: (Context: EvaluationContext, Properties: { [string]: any }) -> EvaluationResult } = {}

Evaluators.Constant = function(_Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueType = Properties.Type or "Number"
	local Value: any

	if ValueType == "Number" then
		Value = Properties.NumberValue or 0
	elseif ValueType == "Boolean" then
		Value = Properties.BooleanValue or false
	elseif ValueType == "String" then
		Value = Properties.StringValue or ""
	end

	return { Value = Value }
end

Evaluators.Compare = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = Context.ResolveInput("A") or Properties.A or 0
	local ValueB = Context.ResolveInput("B") or Properties.B or 0
	local Operator = Properties.Operator or ">"

	local Result = false

	if Operator == ">" then
		Result = ValueA > ValueB
	elseif Operator == "<" then
		Result = ValueA < ValueB
	elseif Operator == ">=" then
		Result = ValueA >= ValueB
	elseif Operator == "<=" then
		Result = ValueA <= ValueB
	elseif Operator == "==" then
		Result = ValueA == ValueB
	elseif Operator == "!=" then
		Result = ValueA ~= ValueB
	end

	return { Result = Result }
end

Evaluators.Math = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = Context.ResolveInput("A") or Properties.A or 0
	local ValueB = Context.ResolveInput("B") or Properties.B or 0
	local Operator = Properties.Operator or "+"

	local Result = 0

	if Operator == "+" then
		Result = ValueA + ValueB
	elseif Operator == "-" then
		Result = ValueA - ValueB
	elseif Operator == "*" then
		Result = ValueA * ValueB
	elseif Operator == "/" then
		Result = if ValueB ~= 0 then ValueA / ValueB else 0
	elseif Operator == "%" then
		Result = if ValueB ~= 0 then ValueA % ValueB else 0
	elseif Operator == "^" then
		Result = ValueA ^ ValueB
	elseif Operator == "min" then
		Result = math.min(ValueA, ValueB)
	elseif Operator == "max" then
		Result = math.max(ValueA, ValueB)
	end

	return { Result = Result }
end

Evaluators.Random = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Min = Context.ResolveInput("Min") or Properties.Min or 0
	local Max = Context.ResolveInput("Max") or Properties.Max or 1
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

Evaluators.GetHealth = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Target = Properties.Target or "Self"
	local Character: Model?

	if Target == "Self" then
		Character = Context.Entity and Context.Entity.Character
	elseif Target == "LastHit" then
		Character = Context.LastHitTarget
	end

	local Current = 0
	local Max = 0
	local Percent = 0

	if Character then
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Current = Humanoid.Health
			Max = Humanoid.MaxHealth
			Percent = if Max > 0 then (Current / Max) * 100 else 0
		end
	end

	return {
		Current = Current,
		Max = Max,
		Percent = Percent,
	}
end

Evaluators.GetDistance = function(Context: EvaluationContext, _Properties: { [string]: any }): EvaluationResult
	local SelfCharacter = Context.Entity and Context.Entity.Character
	local TargetCharacter = Context.LastHitTarget

	local Distance = math.huge

	if SelfCharacter and TargetCharacter then
		local SelfRoot = SelfCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
		local TargetRoot = TargetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?

		if SelfRoot and TargetRoot then
			Distance = (SelfRoot.Position - TargetRoot.Position).Magnitude
		end
	end

	return { Distance = Distance }
end

Evaluators.GetTag = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local TagName = Properties.Tag or ""
	local TagValue = false

	if TagName ~= "" and Context.Tags then
		TagValue = Context.Tags[TagName] == true
	end

	return { Value = TagValue }
end

Evaluators.SignalToBool = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Active = false

	if Context.IsSignalActive then
		local SignalId = Properties.SignalId
		if SignalId and SignalId ~= "" then
			Active = Context.IsSignalActive(SignalId)
		end
	end

	return { Active = Active }
end

Evaluators.Clamp = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = Context.ResolveInput("Value") or Properties.Value or 0
	local Min = Context.ResolveInput("Min") or Properties.Min or 0
	local Max = Context.ResolveInput("Max") or Properties.Max or 1

	return { Result = math.clamp(Value, Min, Max) }
end

Evaluators.Lerp = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local From = Context.ResolveInput("From") or Properties.From or 0
	local To = Context.ResolveInput("To") or Properties.To or 1
	local Alpha = Context.ResolveInput("Alpha") or Properties.Alpha or 0.5

	local Result = From + (To - From) * Alpha
	return { Result = Result }
end

Evaluators.Abs = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = Context.ResolveInput("Value") or Properties.Value or 0
	return { Result = math.abs(Value) }
end

Evaluators.Negate = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = Context.ResolveInput("Value") or Properties.Value or 0
	return { Result = -Value }
end

Evaluators.BoolNot = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local Value = Context.ResolveInput("Value")
	if Value == nil then
		Value = Properties.Value or false
	end
	return { Result = not Value }
end

Evaluators.BoolAnd = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = Context.ResolveInput("A")
	local ValueB = Context.ResolveInput("B")

	if ValueA == nil then
        ValueA = Properties.A or false
    end
	if ValueB == nil then
        ValueB = Properties.B or false
    end

	return { Result = ValueA and ValueB }
end

Evaluators.BoolOr = function(Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local ValueA = Context.ResolveInput("A")
	local ValueB = Context.ResolveInput("B")

	if ValueA == nil then
        ValueA = Properties.A or false
    end
	if ValueB == nil then
        ValueB = Properties.B or false
    end

	return { Result = ValueA or ValueB }
end

Evaluators.GetCounter = function(_Context: EvaluationContext, Properties: { [string]: any }): EvaluationResult
	local _CounterId = Properties.CounterId or ""
	local Count = 0

	return { Count = Count }
end

Evaluators.GetElapsedTime = function(_Context: EvaluationContext, _Properties: { [string]: any }): EvaluationResult
	return { Time = 0 }
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

return ValueEvaluator