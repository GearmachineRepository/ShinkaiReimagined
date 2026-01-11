--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local ActionTypes = require(Shared.Types.ActionTypes)
local ExecutionContextModule = require(script.Parent.ExecutionContext)
local GraphExecutor = require(script.Parent.GraphExecutor)
local TimelineConverter = require(script.Parent.TimelineConverter)

type ExecutionEntity = ActionTypes.ExecutionEntity
type ActionDefinition = ActionTypes.ActionDefinition
type ExecutionContext = ActionTypes.ExecutionContext
type Branch = ActionTypes.Branch
type Block = ActionTypes.Block
type HandlerResult = ActionTypes.HandlerResult

local ActionExecutor = {}

function ActionExecutor.CreateContext(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ExecutionContext
	return ExecutionContextModule.Create(Entity, ActionDefinition, EventBus)
end

function ActionExecutor.Run(Context: ExecutionContext)
	local Entity = Context.Entity
	local ActionDefinition = Context.ActionDefinition
	local EventBus = Context.EventBus

	EventBus:Publish(Enums.Combat.Action.Activated, {
		Entity = Entity,
		ActionId = ActionDefinition.ActionId,
	})

	local GraphDef = TimelineConverter.EnsureGraphFormat(ActionDefinition)
	local EntryBranch = GraphExecutor.GetEntryBranch(GraphDef)

	if EntryBranch then
		GraphExecutor.ExecuteBranch(EntryBranch, Context)
	end

	if Context.Canceled then
		EventBus:Publish(Enums.Combat.Action.Canceled, {
			Entity = Entity,
			ActionId = ActionDefinition.ActionId,
		})
	else
		EventBus:Publish(Enums.Combat.Action.Completed, {
			Entity = Entity,
			ActionId = ActionDefinition.ActionId,
		})
	end
end

function ActionExecutor.Execute(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ExecutionContext
	local Context = ActionExecutor.CreateContext(Entity, ActionDefinition, EventBus)
	ActionExecutor.Run(Context)
	return Context
end

function ActionExecutor.ExecuteBranch(
	Context: ExecutionContext,
	BranchName: string
)
	local GraphDef = TimelineConverter.EnsureGraphFormat(Context.ActionDefinition)
	local Branch = GraphExecutor.GetBranch(GraphDef, BranchName)

	if Branch then
		Context.EventBus:Publish(Enums.Combat.Action.BranchChanged, {
			Entity = Context.Entity,
			ActionId = Context.ActionDefinition.ActionId,
			Branch = BranchName,
		})
		GraphExecutor.ExecuteBranch(Branch, Context)
	end
end

function ActionExecutor.Cancel(Context: ExecutionContext)
	if Context and not Context.Canceled then
		Context.Cancel()
	end
end

return ActionExecutor