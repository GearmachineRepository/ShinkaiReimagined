--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)
local Handlers = require(script.Parent.Parent.Handlers)

type ExecutionContext = ActionTypes.ExecutionContext
type Block = ActionTypes.Block
type HandlerResult = ActionTypes.HandlerResult

export type GraphNode = {
	NodeId: string,
	BlockType: string,
	[string]: any,
}

export type GraphWire = {
	WireId: string,
	FromNode: string,
	FromPort: string,
	ToNode: string,
	ToPort: string,
}

export type GraphBranch = {
	Entry: boolean?,
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire },
}

export type GraphDefinition = {
	ActionId: string,
	DisplayName: string?,
	Branches: { [string]: GraphBranch }?,
	Conditions: ActionTypes.ActionConditions?,
	Properties: ActionTypes.ActionProperties?,
}

local GraphExecutor = {}

local function GetWiresFromPort(Wires: { GraphWire }, NodeId: string, PortName: string): { GraphWire }
	local Result = {}
	for _, Wire in Wires do
		if Wire.FromNode == NodeId and Wire.FromPort == PortName then
			table.insert(Result, Wire)
		end
	end
	return Result
end

local function ExecuteNode(
	NodeId: string,
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire },
	Context: ExecutionContext,
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

	local Node = Nodes[NodeId]
	if not Node then
		return
	end

	local BlockType = Node.BlockType

	if BlockType == "BranchStart" then
		local OutWires = GetWiresFromPort(Wires, NodeId, "Out")
		for _, Wire in OutWires do
			ExecuteNode(Wire.ToNode, Nodes, Wires, Context, Visited)
		end
		return
	end

	if BlockType == "Comment" then
		return
	end

	local Handler = Handlers.Get(BlockType)
	if not Handler then
		warn(string.format("[GraphExecutor] No handler for BlockType: %s", BlockType))
		return
	end

	local BlockData: Block = {
		BlockType = BlockType,
	}
	for Key, Value in Node do
		if Key ~= "NodeId" then
			BlockData[Key] = Value
		end
	end

	local Success, Result = pcall(function()
		return Handler.Execute(BlockData, Context)
	end)

	if not Success then
		warn(string.format("[GraphExecutor] Handler error for %s: %s", BlockType, tostring(Result)))
		return
	end

	local HandlerResult = Result :: HandlerResult?

	if Context.Canceled then
		return
	end

	if HandlerResult then
		if HandlerResult.Cancel then
			Context.Cancel()
			return
		end

		if HandlerResult.JumpToBranch then
			return
		end

		if HandlerResult.FlowPort then
			local PortWires = GetWiresFromPort(Wires, NodeId, HandlerResult.FlowPort)
			for _, Wire in PortWires do
				ExecuteNode(Wire.ToNode, Nodes, Wires, Context, {})
			end
			return
		end
	end

	local OutWires = GetWiresFromPort(Wires, NodeId, "Out")
	for _, Wire in OutWires do
		ExecuteNode(Wire.ToNode, Nodes, Wires, Context, Visited)
	end
end

function GraphExecutor.ExecuteBranch(
	Branch: GraphBranch,
	Context: ExecutionContext
)
	local Nodes = Branch.Nodes
	local Wires = Branch.Wires

	if not Nodes or not Wires then
		return
	end

	local StartNodeId: string? = nil
	for NodeId, Node in Nodes do
		if Node.BlockType == "BranchStart" then
			StartNodeId = NodeId
			break
		end
	end

	if not StartNodeId then
		for NodeId, Node in Nodes do
			if Node.BlockType ~= "Comment" then
				StartNodeId = NodeId
				break
			end
		end
	end

	if not StartNodeId then
		return
	end

	ExecuteNode(StartNodeId, Nodes, Wires, Context, {})
end

function GraphExecutor.GetEntryBranch(Definition: GraphDefinition): GraphBranch?
	local Branches = Definition.Branches
	if not Branches then
		return nil
	end

	for _, BranchData in Branches do
		if BranchData.Entry then
			return BranchData
		end
	end

	local MainBranch = Branches["Main"]
	if MainBranch then
		return MainBranch
	end

	for _, BranchData in Branches do
		return BranchData
	end

	return nil
end

function GraphExecutor.GetBranch(Definition: GraphDefinition, BranchName: string): GraphBranch?
	local Branches = Definition.Branches
	if not Branches then
		return nil
	end
	return Branches[BranchName]
end

return GraphExecutor