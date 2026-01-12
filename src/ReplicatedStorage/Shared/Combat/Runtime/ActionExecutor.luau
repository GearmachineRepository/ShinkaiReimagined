--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local ActionTypes = require(Shared.Types.ActionTypes)

local ActionInstance = require(script.Parent.ActionInstance)
local TimelineConverter = require(script.Parent.Parent.TimelineConverter)
local GraphCompiler = require(script.Parent.Parent.Graph.Compiler)
local GraphRuntime = require(script.Parent.Parent.Graph.Runtime)
local ExecutionContextModule = require(script.Parent.ExecutionContext)
local ValueEvaluator = require(script.Parent.Parent.Graph.ValueEvaluator)
local BlockDefs = require(script.Parent.Parent.BlockDefinitions)

type ExecutionEntity = ActionTypes.ExecutionEntity
type ActionDefinition = ActionTypes.ActionDefinition
type ExecutionContext = ActionTypes.ExecutionContext
type ActionInstanceHandle = ActionInstance.ActionInstanceHandle
type CompiledGraph = GraphCompiler.CompiledGraph

local ActionExecutor = {}

local CompiledGraphCache: { [string]: CompiledGraph } = {}

local function GetOrCompileGraph(ActionDefinition: ActionDefinition): CompiledGraph
	local ActionId = ActionDefinition.ActionId

	if CompiledGraphCache[ActionId] then
		return CompiledGraphCache[ActionId]
	end

	local GraphDef = TimelineConverter.EnsureGraphFormat(ActionDefinition)
	local Compiled = GraphCompiler.Compile(GraphDef)

	CompiledGraphCache[ActionId] = Compiled
	return Compiled
end

function ActionExecutor.ClearCache(ActionId: string?)
	if ActionId then
		CompiledGraphCache[ActionId] = nil
	else
		table.clear(CompiledGraphCache)
	end
end

function ActionExecutor.CreateContext(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ExecutionContext
	return ExecutionContextModule.Create(Entity, ActionDefinition, EventBus)
end

function ActionExecutor.CreateInstance(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ActionInstanceHandle
	local CompiledGraph = GetOrCompileGraph(ActionDefinition)
	return ActionInstance.Create(Entity, ActionDefinition, CompiledGraph, EventBus)
end

local function LogWatcher(Branch: any, NodeId: string, PropertyName: string, Value: any)
	if not Branch.DebugWatchers then
		return
	end

	local WatchKey = NodeId .. ":" .. PropertyName
	local Watcher = Branch.DebugWatchers[WatchKey]
	if not Watcher then
		return
	end

	local Label = Watcher.Label
	local ValueType = typeof(Value)
	local ValueString: string

	if Value == nil then
		ValueString = "nil"
	elseif ValueType == "number" then
		ValueString = string.format("%g", Value)
	elseif ValueType == "string" then
		ValueString = string.format('"%s"', Value)
	elseif ValueType == "Vector3" then
		ValueString = string.format("(%.2f, %.2f, %.2f)", Value.X, Value.Y, Value.Z)
	else
		ValueString = tostring(Value)
	end

	print(string.format("[Watch] %s = %s (%s)", Label, ValueString, ValueType))
end

function ActionExecutor.Run(Context: ExecutionContext)
	local Entity = Context.Entity
	local ActionDefinition = Context.ActionDefinition
	local EventBus = Context.EventBus

	EventBus:Publish(Enums.Combat.Action.Activated, {
		Entity = Entity,
		ActionId = ActionDefinition.ActionId,
	})

	local CompiledGraph = GetOrCompileGraph(ActionDefinition)

	local ValueCache: { [string]: any } = {}
	local CurrentBranchName = CompiledGraph.EntryBranchName

	local ResolveValue: (NodeId: string, PropertyName: string) -> any

	local function IsOutputProperty(BlockType: string, PropertyName: string): boolean
		local Definition = BlockDefs.Get(BlockType)
		if not Definition then
			return false
		end

		for _, Port in Definition.Ports do
			if Port.Direction == "Output" and Port.PortType == "Value" and Port.Name == PropertyName then
				return true
			end
		end

		return false
	end

	local function EvaluatePureNode(Node: any): { [string]: any }?
		local function ResolveInput(PropertyKey: string): any
			return ResolveValue(Node.NodeId, PropertyKey)
		end

		local EvalContext: ValueEvaluator.EvaluationContext = {
			Entity = Entity,
			LastHitTarget = Context.LastHitTarget,
			Tags = {},
			IsSignalActive = Context.IsSignalActive,
			ResolveInput = ResolveInput,
		}

		return ValueEvaluator.Evaluate(Node.BlockType, EvalContext, Node.Properties)
	end

	ResolveValue = function(NodeId: string, PropertyName: string): any
		local CacheKey = NodeId .. ":" .. PropertyName

		if ValueCache[CacheKey] ~= nil then
			return ValueCache[CacheKey]
		end

		local BranchName = CurrentBranchName
		if not BranchName then
			return nil
		end

		local Branch = CompiledGraph.Branches[BranchName]
		if not Branch then
			return nil
		end

		local Node = Branch.Nodes[NodeId]
		if not Node then
			return nil
		end

		local FinalValue: any = nil

		local ValueSource = GraphCompiler.GetValueSource(CompiledGraph, BranchName, NodeId, PropertyName)

		if ValueSource then
			FinalValue = ResolveValue(ValueSource.FromNodeId, ValueSource.FromPortName)
		else
			local Definition = BlockDefs.Get(Node.BlockType)

			if Definition and Definition.Pure and IsOutputProperty(Node.BlockType, PropertyName) then
				local Result = EvaluatePureNode(Node)
				if Result and Result[PropertyName] ~= nil then
					FinalValue = Result[PropertyName]
				else
					FinalValue = Node.Properties[PropertyName]
				end
			else
				FinalValue = Node.Properties[PropertyName]
			end
		end

		ValueCache[CacheKey] = FinalValue

		LogWatcher(Branch, NodeId, PropertyName, FinalValue)

		return FinalValue
	end

	if CompiledGraph.EntryBranchName then
		GraphRuntime.ExecuteBranch(
			CompiledGraph.EntryBranchName,
			CompiledGraph,
			Context,
			ResolveValue
		)
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

function ActionExecutor.RunInstance(Instance: ActionInstanceHandle)
	local Entity = Instance.Entity
	local ActionId = Instance.ActionId
	local EventBus = Instance.EventBus
	local CompiledGraph = Instance.CompiledGraph :: CompiledGraph

	EventBus:Publish(Enums.Combat.Action.Activated, {
		Entity = Entity,
		ActionId = ActionId,
	})

	Instance.SetState("Running")

	local LegacyContext = ActionInstance.CreateLegacyContext(Instance)

	local function ResolveValue(NodeId: string, PropertyName: string): any
		return Instance.ResolveValue(NodeId, PropertyName)
	end

	if CompiledGraph.EntryBranchName then
		Instance.CurrentBranchName = CompiledGraph.EntryBranchName
		GraphRuntime.ExecuteBranch(
			CompiledGraph.EntryBranchName,
			CompiledGraph,
			LegacyContext,
			ResolveValue
		)
	end

	if Instance.IsCanceled() then
		Instance.SetState("Canceled")
		EventBus:Publish(Enums.Combat.Action.Canceled, {
			Entity = Entity,
			ActionId = ActionId,
		})
	else
		Instance.SetState("Completed")
		EventBus:Publish(Enums.Combat.Action.Completed, {
			Entity = Entity,
			ActionId = ActionId,
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

function ActionExecutor.ExecuteWithInstance(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any
): ActionInstanceHandle
	local Instance = ActionExecutor.CreateInstance(Entity, ActionDefinition, EventBus)
	ActionExecutor.RunInstance(Instance)
	return Instance
end

function ActionExecutor.ExecuteBranch(
	Context: ExecutionContext,
	BranchName: string
)
	local CompiledGraph = GetOrCompileGraph(Context.ActionDefinition)
	local Branch = GraphCompiler.GetBranch(CompiledGraph, BranchName)

	if not Branch then
		return
	end

	Context.EventBus:Publish(Enums.Combat.Action.BranchChanged, {
		Entity = Context.Entity,
		ActionId = Context.ActionDefinition.ActionId,
		Branch = BranchName,
	})

	local ValueCache: { [string]: any } = {}

	local ResolveValue: (NodeId: string, PropertyName: string) -> any

	local function IsOutputProperty(BlockType: string, PropertyName: string): boolean
		local Definition = BlockDefs.Get(BlockType)
		if not Definition then
			return false
		end

		for _, Port in Definition.Ports do
			if Port.Direction == "Output" and Port.PortType == "Value" and Port.Name == PropertyName then
				return true
			end
		end

		return false
	end

	local function EvaluatePureNode(Node: any): { [string]: any }?

		local function ResolveInput(PropertyKey: string): any
			return ResolveValue(Node.NodeId, PropertyKey)
		end

		local EvalContext: ValueEvaluator.EvaluationContext = {
			Entity = Context.Entity,
			LastHitTarget = Context.LastHitTarget,
			Tags = {},
			IsSignalActive = Context.IsSignalActive,
			ResolveInput = ResolveInput,
		}

		return ValueEvaluator.Evaluate(Node.BlockType, EvalContext, Node.Properties)
	end

	ResolveValue = function(NodeId: string, PropertyName: string): any
		local CacheKey = NodeId .. ":" .. PropertyName

		if ValueCache[CacheKey] ~= nil then
			return ValueCache[CacheKey]
		end

		local Node = Branch.Nodes[NodeId]
		if not Node then
			return nil
		end

		local FinalValue: any = nil

		local ValueSource = GraphCompiler.GetValueSource(CompiledGraph, BranchName, NodeId, PropertyName)

		if ValueSource then
			FinalValue = ResolveValue(ValueSource.FromNodeId, ValueSource.FromPortName)
		else
			local Definition = BlockDefs.Get(Node.BlockType)

			if Definition and Definition.Pure and IsOutputProperty(Node.BlockType, PropertyName) then
				local Result = EvaluatePureNode(Node)
				if Result and Result[PropertyName] ~= nil then
					FinalValue = Result[PropertyName]
				else
					FinalValue = Node.Properties[PropertyName]
				end
			else
				FinalValue = Node.Properties[PropertyName]
			end
		end

		ValueCache[CacheKey] = FinalValue

		LogWatcher(NodeId, PropertyName, FinalValue)

		return FinalValue
	end

	GraphRuntime.ExecuteBranch(BranchName, CompiledGraph, Context, ResolveValue)
end

function ActionExecutor.ExecuteInstanceBranch(
	Instance: ActionInstanceHandle,
	BranchName: string
)
	local CompiledGraph = Instance.CompiledGraph :: CompiledGraph
	local Branch = GraphCompiler.GetBranch(CompiledGraph, BranchName)

	if Branch then
		Instance.EventBus:Publish(Enums.Combat.Action.BranchChanged, {
			Entity = Instance.Entity,
			ActionId = Instance.ActionId,
			Branch = BranchName,
		})

		Instance.CurrentBranchName = BranchName
		Instance.ClearValueCache()

		local LegacyContext = ActionInstance.CreateLegacyContext(Instance)

		local function ResolveValue(NodeId: string, PropertyName: string): any
			return Instance.ResolveValue(NodeId, PropertyName)
		end

		GraphRuntime.ExecuteBranch(BranchName, CompiledGraph, LegacyContext, ResolveValue)
	end
end

function ActionExecutor.Cancel(Context: ExecutionContext)
	if Context and not Context.Canceled then
		Context.Cancel()
	end
end

function ActionExecutor.CancelInstance(Instance: ActionInstanceHandle)
	if Instance and not Instance.IsCanceled() then
		Instance.Cancel()
	end
end

return ActionExecutor