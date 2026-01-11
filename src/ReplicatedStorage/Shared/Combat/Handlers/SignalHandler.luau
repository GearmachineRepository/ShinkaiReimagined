--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local SignalHandler = {}

function SignalHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local SignalId = Block.SignalId
	if not SignalId then
		return nil
	end

	local ShouldClear = Block.Clear == true
	local Duration = Block.Duration

	if ShouldClear then
		Context.ClearSignal(SignalId)
	else
		Context.EmitSignal(SignalId, Duration)
	end

	return nil
end

return SignalHandler