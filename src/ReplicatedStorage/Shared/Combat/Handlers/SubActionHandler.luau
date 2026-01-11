--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local SubActionHandler = {}

local ActionRegistry: any = nil

local function GetActionRegistry(): any
	if not ActionRegistry then
		ActionRegistry = require(Shared.Combat.ActionRegistry)
	end
	return ActionRegistry
end

function SubActionHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local ActionId = Block.ActionId

	if not ActionId or ActionId == "" then
		return nil
	end

	local Registry = GetActionRegistry()
	local ActionDef = Registry.Get(ActionId)

	if not ActionDef then
		warn(string.format("[SubActionHandler] Unknown Action: %s", ActionId))
		return nil
	end

	local ActionExecutor = require(script.Parent.Parent.ActionExecutor)
	local SubContext = ActionExecutor.Execute(Context.Entity, ActionDef, Context.EventBus)

	for _, Record in SubContext.HitRecords do
		Context.RecordHit(Record.Target, Record.Damage)
	end

	Context.EmitSignal("OnComplete", 0)

	return nil
end

return SubActionHandler