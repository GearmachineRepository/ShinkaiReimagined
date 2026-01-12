--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local CancelHandler = {}

function CancelHandler.Execute(_Block: Block, _Context: ExecutionContext): HandlerResult?
	return { Cancel = true }
end

return CancelHandler