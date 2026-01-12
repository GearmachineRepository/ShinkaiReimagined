--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local EmitSignalHandler = {}

function EmitSignalHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local SignalId = Block.SignalId or ""
	local Duration = Block.Duration or 0

	if SignalId == "" then
		return nil
	end

	local FullSignalId = Block.NodeId and (Block.NodeId .. ":Signal") or SignalId

	if Context.EmitSignal then
		Context.EmitSignal(FullSignalId, Duration)
	end

	return nil
end

return EmitSignalHandler