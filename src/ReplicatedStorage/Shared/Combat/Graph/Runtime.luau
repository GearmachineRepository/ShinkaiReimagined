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
	ResolveValue: (NodeId: string, PropertyName: string) -> any
): Block
	local BlockData: Block = {
		BlockType = Node.BlockType,
	}

	for PropertyName, PropertyValue in Node.Properties do
		local ResolvedValue = ResolveValue(Node.NodeId, PropertyName)
		BlockData[PropertyName] = if ResolvedValue ~= nil then ResolvedValue else PropertyValue
	end

	return BlockData
end

local function ExecuteNode(
	NodeId: string,
	Branch: CompiledBranch,
	Context: ActionTypes.ExecutionContext,
	ResolveValue: (NodeId: string, PropertyName: string) -> any,
	VisitedInFrame: { [string]: boolean }?
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
			ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, Visited)
		end
		return
	end

	if BlockType == "Comment" then
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
				ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, {})
			end
			return
		end
	end

	local OutTargets = Node.FlowOutputs["Out"] or {}
	for _, Target in pairs(OutTargets) do
		ExecuteNode(Target.ToNodeId, Branch, Context, ResolveValue, Visited)
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

	local EntryNodeId = Branch.EntryNodeId
	if not EntryNodeId then
		warn(string.format("[GraphRuntime] No entry node in branch: %s", BranchName))
		return
	end

	ExecuteNode(EntryNodeId, Branch, Context, ValueResolver, {})
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