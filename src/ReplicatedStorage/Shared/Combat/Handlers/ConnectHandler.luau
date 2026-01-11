--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local ConnectHandler = {}

function ConnectHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local SignalId = Block.Signal or "Default"
	local Duration = Block.Time or 1
	local Range = Block.Range or 50

	Context.EventBus:Publish(Enums.Combat.Signal.Emitted, {
		Entity = Context.Entity,
		SignalId = SignalId,
		Duration = Duration,
		Range = Range,
		Position = Context.Entity.Character:GetPivot().Position,
	})

	return nil
end

return ConnectHandler