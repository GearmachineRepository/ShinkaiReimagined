--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatTypes = require(Shared.Types.CombatTypes)

type Block = CombatTypes.Block
type ExecutionContext = CombatTypes.ExecutionContext
type HandlerResult = CombatTypes.HandlerResult

local OrGateHandler = {}

function OrGateHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local Inputs = Block.Inputs
	if not Inputs or #Inputs == 0 then
		return nil
	end

	local OutputSignal = Block.Output
	local Duration = Block.Duration

	for _, SignalId in Inputs do
		if Context.IsSignalActive(SignalId) then
			if OutputSignal then
				Context.EmitSignal(OutputSignal, Duration)
			end
			return nil
		end
	end

	return nil
end

return OrGateHandler