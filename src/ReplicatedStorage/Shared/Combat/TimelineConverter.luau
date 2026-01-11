--!strict

local HttpService = game:GetService("HttpService")

local TimelineConverter = {}

export type LegacyBlock = {
	BlockType: string,
	[string]: any,
}

export type LegacyBranch = {
	Entry: boolean?,
	Timeline: { LegacyBlock },
}

export type LegacyActionDefinition = {
	ActionId: string,
	DisplayName: string?,
	Timeline: { LegacyBlock }?,
	Branches: { [string]: LegacyBranch }?,
	Conditions: any?,
	Properties: any?,
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
	Conditions: any?,
	Properties: any?,
}

local function GenerateId(): string
	return HttpService:GenerateGUID(false):sub(1, 8)
end

local function ConvertTimelineToBranch(Timeline: { LegacyBlock }, IsEntry: boolean?): GraphBranch
	local Nodes: { [string]: GraphNode } = {}
	local Wires: { GraphWire } = {}

	local StartNodeId = "start_" .. GenerateId()
	Nodes[StartNodeId] = {
		NodeId = StartNodeId,
		BlockType = "BranchStart",
	}

	local PreviousNodeId = StartNodeId
	local PreviousPort = "Out"

	for _, Block in Timeline do
		local NodeId = "node_" .. GenerateId()

		local Node: GraphNode = {
			NodeId = NodeId,
			BlockType = Block.BlockType,
		}

		for Key, Value in Block do
			if Key ~= "BlockType" then
				Node[Key] = Value
			end
		end

		Nodes[NodeId] = Node

		local WireId = "wire_" .. GenerateId()
		table.insert(Wires, {
			WireId = WireId,
			FromNode = PreviousNodeId,
			FromPort = PreviousPort,
			ToNode = NodeId,
			ToPort = "In",
		})

		PreviousNodeId = NodeId
		PreviousPort = "Out"
	end

	return {
		Entry = IsEntry,
		Nodes = Nodes,
		Wires = Wires,
	}
end

function TimelineConverter.Convert(LegacyAction: LegacyActionDefinition): GraphDefinition
	local GraphAction: GraphDefinition = {
		ActionId = LegacyAction.ActionId,
		DisplayName = LegacyAction.DisplayName,
		Conditions = LegacyAction.Conditions,
		Properties = LegacyAction.Properties,
		Branches = {},
	}

    if not GraphAction.Branches then return GraphAction end

	if LegacyAction.Timeline then
		GraphAction.Branches["Main"] = ConvertTimelineToBranch(LegacyAction.Timeline, true)
	elseif LegacyAction.Branches then
		for BranchName, BranchData in LegacyAction.Branches do
			if BranchData.Timeline then
				GraphAction.Branches[BranchName] = ConvertTimelineToBranch(BranchData.Timeline, BranchData.Entry)
			end
		end
	end

	return GraphAction
end

function TimelineConverter.IsLegacyFormat(ActionDefinition: any): boolean
	if type(ActionDefinition) ~= "table" then
		return false
	end

	if ActionDefinition.Timeline then
		return true
	end

	if ActionDefinition.Branches then
		for _, BranchData in ActionDefinition.Branches do
			if BranchData.Timeline and not BranchData.Nodes then
				return true
			end
		end
	end

	return false
end

function TimelineConverter.EnsureGraphFormat(ActionDefinition: any): GraphDefinition
	if TimelineConverter.IsLegacyFormat(ActionDefinition) then
		return TimelineConverter.Convert(ActionDefinition :: LegacyActionDefinition)
	end
	return ActionDefinition :: GraphDefinition
end

return TimelineConverter