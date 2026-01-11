--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local TimerHandler = {}

function TimerHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local InputSignal = Block.Input
	local Delay = Block.Time or 1
	local OutputSignal = Block.Output
	local OutputDuration = Block.OutputDuration

	if InputSignal and not Context.IsSignalActive(InputSignal) then
		return nil
	end

	if not OutputSignal then
		return nil
	end

	task.delay(Delay, function()
		if not Context.Canceled then
			Context.EmitSignal(OutputSignal, OutputDuration)
		end
	end)

	return nil
end

return TimerHandler