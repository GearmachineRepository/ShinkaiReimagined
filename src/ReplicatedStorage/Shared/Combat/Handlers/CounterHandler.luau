--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatTypes = require(Shared.Types.CombatTypes)

type Block = CombatTypes.Block
type ExecutionContext = CombatTypes.ExecutionContext
type HandlerResult = CombatTypes.HandlerResult

local CounterHandler = {}

function CounterHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local CounterId = Block.BlockId or "DefaultCounter"
	local InputSignal = Block.Input
	local Threshold = Block.Threshold or 1
	local OutputSignal = Block.Output
	local Duration = Block.Duration
	local ResetOnThreshold = Block.ResetOnThreshold ~= false

	if InputSignal and not Context.IsSignalActive(InputSignal) then
		return nil
	end

	local NewCount = Context.IncrementCounter(CounterId)

	if NewCount >= Threshold then
		if OutputSignal then
			Context.EmitSignal(OutputSignal, Duration)
		end

		if ResetOnThreshold then
			Context.ResetCounter(CounterId)
		end
	end

	return nil
end

return CounterHandler