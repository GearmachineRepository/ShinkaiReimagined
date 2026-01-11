--!strict

local BlockDefinitions = require(script.Parent.Parent.BlockDefinitions)

local Validator = {}

export type ValidationError = {
	NodeId: string?,
	WireId: string?,
	PortName: string?,
	Code: string,
	Message: string,
}

export type ValidationResult = {
	Valid: boolean,
	Errors: { ValidationError },
	Warnings: { ValidationError },
}

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

local function CreateError(Code: string, Message: string, NodeId: string?, WireId: string?, PortName: string?): ValidationError
	return {
		NodeId = NodeId,
		WireId = WireId,
		PortName = PortName,
		Code = Code,
		Message = Message,
	}
end

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

local function ValidateWirePortMatch(
	Wire: GraphWire,
	FromNode: GraphNode,
	ToNode: GraphNode,
	Errors: { ValidationError }
)
	local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
	local ToPort = GetPortDefinition(ToNode.BlockType, Wire.ToPort, "Input")

	if not FromPort then
		table.insert(Errors, CreateError(
			"INVALID_OUTPUT_PORT",
			string.format("Node '%s' has no output port '%s'", FromNode.BlockType, Wire.FromPort),
			Wire.FromNode,
			Wire.WireId,
			Wire.FromPort
		))
		return
	end

	if not ToPort then
		table.insert(Errors, CreateError(
			"INVALID_INPUT_PORT",
			string.format("Node '%s' has no input port '%s'", ToNode.BlockType, Wire.ToPort),
			Wire.ToNode,
			Wire.WireId,
			Wire.ToPort
		))
		return
	end

	if FromPort.PortType ~= ToPort.PortType then
		table.insert(Errors, CreateError(
			"PORT_TYPE_MISMATCH",
			string.format("Cannot connect %s port to %s port", FromPort.PortType, ToPort.PortType),
			nil,
			Wire.WireId,
			nil
		))
	end
end

local function ValidateSingleInputConnection(
	Wires: { GraphWire },
	Nodes: { [string]: GraphNode },
	Errors: { ValidationError }
)
	local InputConnections: { [string]: { WireId: string, PortType: string } } = {}

	for _, Wire in Wires do
		local ToNode = Nodes[Wire.ToNode]
		if not ToNode then
			continue
		end

		local ToPort = GetPortDefinition(ToNode.BlockType, Wire.ToPort, "Input")
		if not ToPort then
			continue
		end

		local ConnectionKey = Wire.ToNode .. ":" .. Wire.ToPort

		if InputConnections[ConnectionKey] then
			table.insert(Errors, CreateError(
				"MULTIPLE_INPUT_CONNECTIONS",
				string.format("Input port '%s' on '%s' has multiple connections", Wire.ToPort, ToNode.BlockType),
				Wire.ToNode,
				Wire.WireId,
				Wire.ToPort
			))
		else
			InputConnections[ConnectionKey] = {
				WireId = Wire.WireId,
				PortType = ToPort.PortType,
			}
		end
	end
end

local function DetectCycles(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire },
	PortTypeFilter: string?,
	Errors: { ValidationError }
): boolean
	local Adjacency: { [string]: { string } } = {}
	for NodeId in Nodes do
		Adjacency[NodeId] = {}
	end

	for _, Wire in Wires do
		if PortTypeFilter then
			local FromNode = Nodes[Wire.FromNode]
			if FromNode then
				local FromPort = GetPortDefinition(FromNode.BlockType, Wire.FromPort, "Output")
				if FromPort and FromPort.PortType ~= PortTypeFilter then
					continue
				end
			end
		end

		if Adjacency[Wire.FromNode] then
			table.insert(Adjacency[Wire.FromNode], Wire.ToNode)
		end
	end

	local WHITE = 0
	local GRAY = 1
	local BLACK = 2

	local Colors: { [string]: number } = {}
	for NodeId in Nodes do
		Colors[NodeId] = WHITE
	end

	local function DepthFirstSearch(NodeId: string): boolean
		Colors[NodeId] = GRAY

		local Neighbors = Adjacency[NodeId]
		if Neighbors then
			for _, NeighborId in Neighbors do
				local NeighborColor = Colors[NeighborId]
				if NeighborColor == GRAY then
					return true
				elseif NeighborColor == WHITE then
					if DepthFirstSearch(NeighborId) then
						return true
					end
				end
			end
		end

		Colors[NodeId] = BLACK
		return false
	end

	for NodeId in Nodes do
		if Colors[NodeId] == WHITE then
			if DepthFirstSearch(NodeId) then
				local FilterDesc = if PortTypeFilter then PortTypeFilter .. " " else ""
				table.insert(Errors, CreateError(
					"CYCLE_DETECTED",
					string.format("Cycle detected in %swire graph", FilterDesc),
					nil,
					nil,
					nil
				))
				return true
			end
		end
	end

	return false
end

local function ValidateEntryNode(
	Nodes: { [string]: GraphNode },
	Errors: { ValidationError }
): boolean
	for _, Node in Nodes do
		if Node.BlockType == "BranchStart" then
			return true
		end
	end

	table.insert(Errors, CreateError(
		"NO_ENTRY_NODE",
		"Branch has no BranchStart node",
		nil,
		nil,
		nil
	))

	return false
end

local function ValidateRequiredFlowInput(
	Nodes: { [string]: GraphNode },
	Wires: { GraphWire },
	Warnings: { ValidationError }
)
	local ConnectedInputs: { [string]: boolean } = {}

	for _, Wire in Wires do
		local ToNode = Nodes[Wire.ToNode]
		if not ToNode then
			continue
		end

		local ToPort = GetPortDefinition(ToNode.BlockType, Wire.ToPort, "Input")
		if ToPort and ToPort.PortType == "Flow" then
			ConnectedInputs[Wire.ToNode .. ":" .. Wire.ToPort] = true
		end
	end

	for NodeId, Node in Nodes do
		if Node.BlockType == "BranchStart" or Node.BlockType == "Comment" then
			continue
		end

		local Definition = BlockDefinitions.Get(Node.BlockType)
		if not Definition then
			continue
		end

		for _, Port in Definition.Ports do
			if Port.Direction == "Input" and Port.PortType == "Flow" then
				local ConnectionKey = NodeId .. ":" .. Port.Name
				if not ConnectedInputs[ConnectionKey] then
					table.insert(Warnings, CreateError(
						"UNCONNECTED_FLOW_INPUT",
						string.format("Node '%s' has unconnected flow input '%s'", Node.BlockType, Port.Name),
						NodeId,
						nil,
						Port.Name
					))
				end
			end
		end
	end
end

local function ValidateNodeExists(
	Wires: { GraphWire },
	Nodes: { [string]: GraphNode },
	Errors: { ValidationError }
)
	for _, Wire in Wires do
		if not Nodes[Wire.FromNode] then
			table.insert(Errors, CreateError(
				"MISSING_NODE",
				string.format("Wire references non-existent node '%s'", Wire.FromNode),
				nil,
				Wire.WireId,
				nil
			))
		end

		if not Nodes[Wire.ToNode] then
			table.insert(Errors, CreateError(
				"MISSING_NODE",
				string.format("Wire references non-existent node '%s'", Wire.ToNode),
				nil,
				Wire.WireId,
				nil
			))
		end
	end
end

local function ValidateBlockTypeExists(
	Nodes: { [string]: GraphNode },
	Errors: { ValidationError }
)
	for NodeId, Node in Nodes do
		local Definition = BlockDefinitions.Get(Node.BlockType)
		if not Definition then
			table.insert(Errors, CreateError(
				"UNKNOWN_BLOCK_TYPE",
				string.format("Unknown block type '%s'", Node.BlockType),
				NodeId,
				nil,
				nil
			))
		end
	end
end

function Validator.ValidateBranch(Branch: GraphBranch): ValidationResult
	local Errors: { ValidationError } = {}
	local Warnings: { ValidationError } = {}

	local Nodes = Branch.Nodes or {}
	local Wires = Branch.Wires or {}

	ValidateBlockTypeExists(Nodes, Errors)

	if #Errors > 0 then
		return {
			Valid = false,
			Errors = Errors,
			Warnings = Warnings,
		}
	end

	ValidateNodeExists(Wires, Nodes, Errors)
	ValidateEntryNode(Nodes, Errors)

	for _, Wire in pairs(Wires) do
		local FromNode = Nodes[Wire.FromNode]
		local ToNode = Nodes[Wire.ToNode]

		if FromNode and ToNode then
			ValidateWirePortMatch(Wire, FromNode, ToNode, Errors)
		end
	end

	ValidateSingleInputConnection(Wires, Nodes, Errors)
	DetectCycles(Nodes, Wires, "Value", Errors)
	ValidateRequiredFlowInput(Nodes, Wires, Warnings)

	return {
		Valid = #Errors == 0,
		Errors = Errors,
		Warnings = Warnings,
	}
end

function Validator.ValidateGraph(Definition: GraphDefinition): ValidationResult
	local AllErrors: { ValidationError } = {}
	local AllWarnings: { ValidationError } = {}

	if not Definition.ActionId or Definition.ActionId == "" then
		table.insert(AllErrors, CreateError(
			"MISSING_ACTION_ID",
			"Graph definition is missing ActionId",
			nil,
			nil,
			nil
		))
	end

	local Branches = Definition.Branches
	if not Branches then
		table.insert(AllErrors, CreateError(
			"NO_BRANCHES",
			"Graph definition has no branches",
			nil,
			nil,
			nil
		))
		return {
			Valid = false,
			Errors = AllErrors,
			Warnings = AllWarnings,
		}
	end

	local HasEntryBranch = false
	for BranchName, Branch in Branches do
		if Branch.Entry then
			HasEntryBranch = true
		end

		local BranchResult = Validator.ValidateBranch(Branch)

		for _, Error in BranchResult.Errors do
			Error.Message = string.format("[%s] %s", BranchName, Error.Message)
			table.insert(AllErrors, Error)
		end

		for _, Warning in BranchResult.Warnings do
			Warning.Message = string.format("[%s] %s", BranchName, Warning.Message)
			table.insert(AllWarnings, Warning)
		end
	end

	if not HasEntryBranch then
		if Branches["Main"] then
			table.insert(AllWarnings, CreateError(
				"NO_ENTRY_FLAG",
				"No branch marked as entry, defaulting to 'Main'",
				nil,
				nil,
				nil
			))
		else
			table.insert(AllErrors, CreateError(
				"NO_ENTRY_BRANCH",
				"No branch is marked as entry and no 'Main' branch exists",
				nil,
				nil,
				nil
			))
		end
	end

	return {
		Valid = #AllErrors == 0,
		Errors = AllErrors,
		Warnings = AllWarnings,
	}
end

function Validator.GetErrorSummary(Result: ValidationResult): string
	if Result.Valid and #Result.Warnings == 0 then
		return "Graph is valid"
	end

	local Lines: { string } = {}

	if not Result.Valid then
		table.insert(Lines, string.format("Validation failed with %d error(s):", #Result.Errors))
		for Index, Error in Result.Errors do
			table.insert(Lines, string.format("  %d. [%s] %s", Index, Error.Code, Error.Message))
		end
	end

	if #Result.Warnings > 0 then
		table.insert(Lines, string.format("%d warning(s):", #Result.Warnings))
		for Index, Warning in Result.Warnings do
			table.insert(Lines, string.format("  %d. [%s] %s", Index, Warning.Code, Warning.Message))
		end
	end

	return table.concat(Lines, "\n")
end

return Validator