--!strict

local BlockDefinitions = require(script.Parent.Parent.BlockDefinitions)

local Compiler = {}

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
}

export type FlowConnection = {
	ToNodeId: string,
	ToPortName: string,
}

export type SignalListener = {
	NodeId: string,
	PortName: string,
}

export type ValueSource = {
	FromNodeId: string,
	FromPortName: string,
}

export type CompiledNode = {
	NodeId: string,
	BlockType: string,
	Properties: { [string]: any },
	FlowOutputs: { [string]: { FlowConnection } },
	SignalOutputs: { [string]: { SignalListener } },
	ValueInputs: { [string]: ValueSource },
}

export type CompiledBranch = {
	BranchName: string,
	Entry: boolean,
	EntryNodeId: string?,
	Nodes: { [string]: CompiledNode },
	SignalListeners: { [string]: { SignalListener } },
	SignalInputs: { [string]: { [string]: { FromNodeId: string, FromPortName: string } } }?,
	ValueEvaluationOrder: { string },
	DebugWatchers: { [string]: { Label: string, PrintNodeId: string } }?,
}

export type CompiledGraph = {
	ActionId: string,
	DisplayName: string,
	Branches: { [string]: CompiledBranch },
	EntryBranchName: string?,
	Valid: boolean,
}

local function GetPortDefinition(BlockType: string, PortName: string, Direction: "Input" | "Output"): BlockDefinitions.PortDefinition?
	local Definition = BlockDefinitions.Get(BlockType)
	if not Definition then
		return nil
	end

	for _, Port in Definition.Ports do
		if Port.Name == PortName and Port.Direction == Direction then
			return Port
		end
	end

	return nil
end

local function BuildSignalInputs(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { [string]: { [string]: { FromNodeId: string, FromPortName: string } } }
	local SignalInputMap: { [string]: { [string]: { FromNodeId: string, FromPortName: string } } } = {}

	for _, Wire in Wires do
		local FromNode = Nodes[Wire.FromNode]
		local ToNode = Nodes[Wire.ToNode]
		if not FromNode or not ToNode then
			continue
		end

		local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
		if not FromPort or FromPort.PortType ~= "Signal" then
			continue
		end

		if not SignalInputMap[Wire.ToNode] then
			SignalInputMap[Wire.ToNode] = {}
		end

		SignalInputMap[Wire.ToNode][Wire.ToPort] = {
			FromNodeId = Wire.FromNode,
			FromPortName = Wire.FromPort,
		}
	end

	return SignalInputMap
end

local function BuildDebugWatchers(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { [string]: { Label: string, PrintNodeId: string } }
	local Watchers: { [string]: { Label: string, PrintNodeId: string } } = {}

	for _, Wire in Wires do
		local ToNode = Nodes[Wire.ToNode]
		if not ToNode then
			continue
		end

		if ToNode.BlockType ~= "Print" then
			continue
		end

		local WatchKey = Wire.FromNode .. ":" .. Wire.FromPort
		local Label = ToNode.Label or "Print"

		if ToNode.Properties and ToNode.Properties.Label then
			Label = ToNode.Properties.Label
		end

		Watchers[WatchKey] = {
			Label = Label,
			PrintNodeId = Wire.ToNode,
		}
	end

	return Watchers
end

local function GetDefaultProperties(BlockType: string): { [string]: any }
	local Definition = BlockDefinitions.Get(BlockType)
	if not Definition then
		return {}
	end

	local Defaults: { [string]: any } = {}
	for _, PropertyDef in Definition.Properties do
		Defaults[PropertyDef.Key] = PropertyDef.Default
	end

	return Defaults
end

local function BuildFlowAdjacency(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { [string]: { [string]: { FlowConnection } } }
	local FlowMap: { [string]: { [string]: { FlowConnection } } } = {}

	for NodeId in Nodes do
		FlowMap[NodeId] = {}
	end

	for _, Wire in Wires do
		local FromNode = Nodes[Wire.FromNode]
		if not FromNode then
			continue
		end

		local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
		if not FromPort or FromPort.PortType ~= "Flow" then
			continue
		end

		local NodeFlowMap = FlowMap[Wire.FromNode]
		if not NodeFlowMap then
			continue
		end

		if not NodeFlowMap[Wire.FromPort] then
			NodeFlowMap[Wire.FromPort] = {}
		end

		table.insert(NodeFlowMap[Wire.FromPort], {
			ToNodeId = Wire.ToNode,
			ToPortName = Wire.ToPort,
		})
	end

	return FlowMap
end

local function BuildSignalListeners(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { [string]: { SignalListener } }
	local SignalMap: { [string]: { SignalListener } } = {}

	for _, Wire in Wires do
		local FromNode = Nodes[Wire.FromNode]
		if not FromNode then
			continue
		end

		local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
		if not FromPort or FromPort.PortType ~= "Signal" then
			continue
		end

		local SignalKey = Wire.FromNode .. ":" .. Wire.FromPort

		if not SignalMap[SignalKey] then
			SignalMap[SignalKey] = {}
		end

		table.insert(SignalMap[SignalKey], {
			NodeId = Wire.ToNode,
			PortName = Wire.ToPort,
		})
	end

	return SignalMap
end

local function BuildValueInputs(
	NodeId: string,
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { [string]: ValueSource }
	local ValueMap: { [string]: ValueSource } = {}

	for _, Wire in Wires do
		if Wire.ToNode ~= NodeId then
			continue
		end

		local FromNode = Nodes[Wire.FromNode]
		if not FromNode then
			continue
		end

		local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
		if not FromPort or FromPort.PortType ~= "Value" then
			continue
		end

		ValueMap[Wire.ToPort] = {
			FromNodeId = Wire.FromNode,
			FromPortName = Wire.FromPort,
		}
	end

	return ValueMap
end

local function ComputeValueEvaluationOrder(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire }
): { string }
	local ValueNodeIds: { [string]: boolean } = {}
	local Dependencies: { [string]: { string } } = {}

	for NodeId, Node in Nodes do
		local Definition = BlockDefinitions.Get(Node.BlockType)
		if not Definition then
			continue
		end

		local HasValueOutput = false
		for _, Port in Definition.Ports do
			if Port.Direction == "Output" and Port.PortType == "Value" then
				HasValueOutput = true
				break
			end
		end

		if HasValueOutput then
			ValueNodeIds[NodeId] = true
			Dependencies[NodeId] = {}
		end
	end

	for _, Wire in Wires do
		local FromNode = Nodes[Wire.FromNode]
		local ToNode = Nodes[Wire.ToNode]

		if not FromNode or not ToNode then
			continue
		end

		local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
		if not FromPort or FromPort.PortType ~= "Value" then
			continue
		end

		if ValueNodeIds[Wire.ToNode] and ValueNodeIds[Wire.FromNode] then
			table.insert(Dependencies[Wire.ToNode], Wire.FromNode)
		end
	end

	local Visited: { [string]: boolean } = {}
	local Order: { string } = {}

	local function Visit(NodeId: string)
		if Visited[NodeId] then
			return
		end

		Visited[NodeId] = true

		local Deps = Dependencies[NodeId]
		if Deps then
			for _, DepId in Deps do
				Visit(DepId)
			end
		end

		table.insert(Order, NodeId)
	end

	for NodeId in ValueNodeIds do
		Visit(NodeId)
	end

	return Order
end

local function FindEntryNode(Nodes: { [string]: GraphNode }): string?
	for NodeId, Node in Nodes do
		if Node.BlockType == "BranchStart" then
			return NodeId
		end
	end

	return nil
end

function Compiler.CompileBranch(BranchName: string, Branch: GraphBranch): CompiledBranch
	local Nodes = Branch.Nodes or {}
	local Wires = Branch.Wires or {}

	local FlowAdjacency = BuildFlowAdjacency(Nodes, Wires)
	local SignalListeners = BuildSignalListeners(Nodes, Wires)
	local ValueOrder = ComputeValueEvaluationOrder(Nodes, Wires)
	local DebugWatchers = BuildDebugWatchers(Nodes, Wires)
	local SignalInputs = BuildSignalInputs(Nodes, Wires)

	local CompiledNodes: { [string]: CompiledNode } = {}

	for NodeId, Node in pairs(Nodes) do
		local DefaultProps = GetDefaultProperties(Node.BlockType)
		local Properties: { [string]: any } = {}

		for Key, Default in DefaultProps do
			Properties[Key] = if Node[Key] ~= nil then Node[Key] else Default
		end

		CompiledNodes[NodeId] = {
			NodeId = NodeId,
			BlockType = Node.BlockType,
			Properties = Properties,
			FlowOutputs = FlowAdjacency[NodeId] or {},
			SignalOutputs = {},
			ValueInputs = BuildValueInputs(NodeId, Nodes, Wires),
		}
	end

	for SignalKey, Listeners in SignalListeners do
		local Parts = string.split(SignalKey, ":")
		local NodeId = Parts[1]
		local PortName = Parts[2]

		local CompiledNode = CompiledNodes[NodeId]
		if CompiledNode then
			CompiledNode.SignalOutputs[PortName] = Listeners
		end
	end

	return {
		BranchName = BranchName,
		Entry = Branch.Entry == true,
		EntryNodeId = FindEntryNode(Nodes),
		Nodes = CompiledNodes,
		SignalListeners = SignalListeners,
		ValueEvaluationOrder = ValueOrder,
		DebugWatchers = DebugWatchers,
		SignalInputs = SignalInputs,
	}
end

function Compiler.Compile(Definition: GraphDefinition): CompiledGraph
	local CompiledBranches: { [string]: CompiledBranch } = {}
	local EntryBranchName: string? = nil

	local Branches = Definition.Branches
	if Branches then
		for BranchName, Branch in Branches do
			local Compiled = Compiler.CompileBranch(BranchName, Branch)
			CompiledBranches[BranchName] = Compiled

			if Compiled.Entry then
				EntryBranchName = BranchName
			end
		end
	end

	if not EntryBranchName and CompiledBranches["Main"] then
		EntryBranchName = "Main"
		CompiledBranches["Main"].Entry = true
	end

	if not EntryBranchName then
		for BranchName, _ in CompiledBranches do
			EntryBranchName = BranchName
			break
		end
	end

	return {
		ActionId = Definition.ActionId or "",
		DisplayName = Definition.DisplayName or Definition.ActionId or "",
		Branches = CompiledBranches,
		EntryBranchName = EntryBranchName,
		Valid = EntryBranchName ~= nil,
	}
end

function Compiler.GetFlowTargets(
	CompiledGraphRef: CompiledGraph,
	BranchName: string,
	NodeId: string,
	PortName: string
): { FlowConnection }
	local Branch = CompiledGraphRef.Branches[BranchName]
	if not Branch then
		return {}
	end

	local Node = Branch.Nodes[NodeId]
	if not Node then
		return {}
	end

	return Node.FlowOutputs[PortName] or {}
end

function Compiler.GetSignalListeners(
	CompiledGraphRef: CompiledGraph,
	BranchName: string,
	NodeId: string,
	PortName: string
): { SignalListener }
	local Branch = CompiledGraphRef.Branches[BranchName]
	if not Branch then
		return {}
	end

	local Node = Branch.Nodes[NodeId]
	if not Node then
		return {}
	end

	return Node.SignalOutputs[PortName] or {}
end

function Compiler.GetValueSource(
	CompiledGraphRef: CompiledGraph,
	BranchName: string,
	NodeId: string,
	PropertyName: string
): ValueSource?
	local Branch = CompiledGraphRef.Branches[BranchName]
	if not Branch then
		return nil
	end

	local Node = Branch.Nodes[NodeId]
	if not Node then
		return nil
	end

	return Node.ValueInputs[PropertyName]
end

function Compiler.GetNodeProperty(
	CompiledGraphRef: CompiledGraph,
	BranchName: string,
	NodeId: string,
	PropertyName: string
): any
	local Branch = CompiledGraphRef.Branches[BranchName]
	if not Branch then
		return nil
	end

	local Node = Branch.Nodes[NodeId]
	if not Node then
		return nil
	end

	return Node.Properties[PropertyName]
end

function Compiler.GetEntryBranch(CompiledGraphRef: CompiledGraph): CompiledBranch?
	if not CompiledGraphRef.EntryBranchName then
		return nil
	end

	return CompiledGraphRef.Branches[CompiledGraphRef.EntryBranchName]
end

function Compiler.GetBranch(CompiledGraphRef: CompiledGraph, BranchName: string): CompiledBranch?
	return CompiledGraphRef.Branches[BranchName]
end

return Compiler