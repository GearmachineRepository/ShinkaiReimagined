--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local NotGateHandler = {}

function NotGateHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local InputSignal = Block.Input
	if not InputSignal then
		return nil
	end

	local OutputSignal = Block.Output
	local Duration = Block.Duration

	if not Context.IsSignalActive(InputSignal) then
		if OutputSignal then
			Context.EmitSignal(OutputSignal, Duration)
		end
	end

	return nil
end

return NotGateHandler