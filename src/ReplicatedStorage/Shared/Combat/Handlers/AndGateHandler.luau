--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatTypes = require(Shared.Types.CombatTypes)

type Block = CombatTypes.Block
type ExecutionContext = CombatTypes.ExecutionContext
type HandlerResult = CombatTypes.HandlerResult

local AndGateHandler = {}

function AndGateHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local Inputs = Block.Inputs
	if not Inputs or #Inputs == 0 then
		return nil
	end

	local Threshold = Block.Threshold or #Inputs
	local OutputSignal = Block.Output
	local Duration = Block.Duration

	local ActiveCount = 0
	for _, SignalId in Inputs do
		if Context.IsSignalActive(SignalId) then
			ActiveCount = ActiveCount + 1
		end
	end

	if ActiveCount >= Threshold and OutputSignal then
		Context.EmitSignal(OutputSignal, Duration)
	end

	return nil
end

return AndGateHandler