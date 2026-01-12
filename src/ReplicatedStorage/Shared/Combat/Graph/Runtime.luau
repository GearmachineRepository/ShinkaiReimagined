--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

local Handlers = require(script.Parent.Parent.Handlers)
local Compiler = require(script.Parent.Compiler)

type CompiledGraph = Compiler.CompiledGraph
type CompiledBranch = Compiler.CompiledBranch
type CompiledNode = Compiler.CompiledNode
type FlowConnection = Compiler.FlowConnection
type Block = ActionTypes.Block
type HandlerResult = ActionTypes.HandlerResult

local Runtime = {}

local function BuildBlockFromNode(
	Node: CompiledNode,
	ResolveValue: ((NodeId: string, PropertyName: string) -> any)?
): Block
	local BlockData: Block = {
		BlockType = Node.BlockType,
		NodeId = Node.NodeId,
	}

	for PropertyName, PropertyValue in Node.Properties do
		local ResolvedValue = nil
		if ResolveValue then
			ResolvedValue = ResolveValue(Node.NodeId, PropertyName)
		end
		BlockData[PropertyName] = if ResolvedValue ~= nil then ResolvedValue else PropertyValue
	end

	if Node.SignalOutputs and next(Node.SignalOutputs) then
		BlockData.Outputs = BlockData.Outputs or {}
		for PortName, _Listeners in Node.SignalOutputs do
			local SignalId = Node.NodeId .. ":" .. PortName
			BlockData.Outputs[PortName] = SignalId
		end
	end

	return BlockData
end

local function ExecuteNode(
	NodeId: string,
	Branch: CompiledBranch,
	Context: ActionTypes.ExecutionContext,
	ResolveValue: ((NodeId: string, PropertyName: string) -> any)?,
	VisitedInFrame: { [string]: boolean }?,
	TriggerSignalFlow: ((SignalId: string) -> ())?
)
	if Context.Canceled then
		return
	end

	local Visited = VisitedInFrame or {}
	if Visited[NodeId] then
		return
	end
	Visited[NodeId] = true

	local Node = Branch.Nodes[NodeId]
	if not Node then
		return
	end

	local BlockType = Node.BlockType

	if BlockType == "BranchStart" then
		local FlowTargets = Node.FlowOutputs["Out"] or {}
		for _, Target in pairs(FlowTargets) do
			ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, Visited, TriggerSignalFlow)
		end
		return
	end

	if BlockType == "Comment" or BlockType == "Print" then
		return
	end

	if BlockType == "Gate" then
		return
	end

	local Handler = Handlers.Get(BlockType)
	if not Handler then
		warn(string.format("[GraphRuntime] No handler for BlockType: %s", BlockType))
		return
	end

	local BlockData = BuildBlockFromNode(Node, ResolveValue)

	local Success, Result = pcall(function()
		return Handler.Execute(BlockData, Context)
	end)

	if not Success then
		warn(string.format("[GraphRuntime] Handler error for %s: %s", BlockType, tostring(Result)))
		return
	end

	if Context.Canceled then
		return
	end

	local HandlerResult = Result :: HandlerResult?

	if HandlerResult then
		if HandlerResult.Cancel then
			Context.Cancel()
			return
		end

		if HandlerResult.JumpToBranch then
			return
		end

		if HandlerResult.FlowPort then
			local PortTargets = Node.FlowOutputs[HandlerResult.FlowPort] or {}
			for _, Target in pairs(PortTargets) do
				ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, {}, TriggerSignalFlow)
			end
			return
		end
	end

	local OutTargets = Node.FlowOutputs["Out"] or {}
	for _, Target in pairs(OutTargets) do
		ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, Visited, TriggerSignalFlow)
	end
end

function Runtime.ExecuteBranch(
	BranchName: string,
	CompiledGraphRef: CompiledGraph,
	Context: ActionTypes.ExecutionContext,
	ResolveValue: ((NodeId: string, PropertyName: string) -> any)?
)
	local Branch = CompiledGraphRef.Branches[BranchName]
	if not Branch then
		warn(string.format("[GraphRuntime] Branch not found: %s", BranchName))
		return
	end

	local ValueResolver = ResolveValue or function(NodeId: string, PropertyName: string): any
		local Node = Branch.Nodes[NodeId]
		if Node then
			return Node.Properties[PropertyName]
		end
		return nil
	end

	local OriginalEmitSignal = Context.EmitSignal

	local function TriggerSignalFlow(SignalId: string)
		local Listeners = Branch.SignalListeners[SignalId]
		if not Listeners then
			return
		end

		for _, Listener in Listeners do
			local ListenerNode = Branch.Nodes[Listener.NodeId]
			if not ListenerNode then
				continue
			end

			if ListenerNode.BlockType == "Gate" then
				local FlowTargets = ListenerNode.FlowOutputs["Out"] or {}
				for _, Target in pairs(FlowTargets) do
					task.spawn(function()
						ExecuteNode(Target.ToNodeId, Branch, Context, ValueResolver, {}, TriggerSignalFlow)
					end)
				end
			end
		end
	end

	local function WrappedEmitSignal(SignalId: string, Duration: number?)
		OriginalEmitSignal(SignalId, Duration)
		TriggerSignalFlow(SignalId)
	end

	local ContextProxy = setmetatable({}, {
		__index = function(_, Key)
			if Key == "EmitSignal" then
				return WrappedEmitSignal
			end
			return (Context :: any)[Key]
		end,
		__newindex = function(_, Key, Value)
			(Context :: any)[Key] = Value
		end,
	})

	local EntryNodeId = Branch.EntryNodeId
	if not EntryNodeId then
		warn(string.format("[GraphRuntime] No entry node in branch: %s", BranchName))
		return
	end

	ExecuteNode(EntryNodeId, Branch, ContextProxy :: any, ValueResolver, {}, TriggerSignalFlow)
end

function Runtime.ExecuteEntryBranch(
	CompiledGraphRef: CompiledGraph,
	Context: ActionTypes.ExecutionContext,
	ResolveValue: ((NodeId: string, PropertyName: string) -> any)?
)
	local EntryBranchName = CompiledGraphRef.EntryBranchName
	if not EntryBranchName then
		warn("[GraphRuntime] No entry branch in compiled graph")
		return
	end

	Runtime.ExecuteBranch(EntryBranchName, CompiledGraphRef, Context, ResolveValue)
end

function Runtime.GetFlowTargets(
	CompiledGraphRef: CompiledGraph,
	BranchName: string,
	NodeId: string,
	PortName: string
): { FlowConnection }
	return Compiler.GetFlowTargets(CompiledGraphRef, BranchName, NodeId, PortName)
end

return Runtime