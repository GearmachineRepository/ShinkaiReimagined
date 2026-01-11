--!strict

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent.Types)
local Theme = require(script.Parent.Parent.Theme)
local Comment = require(script.Parent.Parent.Graph.Comment)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)

local ActionSerializer = {}

local function SerializeComments(Comments: { Types.CommentData }?): { any }
	if not Comments then
		return {}
	end

	local Serialized = {}
	for _, CommentData in Comments do
		table.insert(Serialized, {
			CommentId = CommentData.CommentId,
			Title = CommentData.Title,
			Text = CommentData.Text,
			Color = {
				R = CommentData.Color.R,
				G = CommentData.Color.G,
				B = CommentData.Color.B,
			},
			Position = {
				X = CommentData.Position.X,
				Y = CommentData.Position.Y,
			},
			Size = {
				X = CommentData.Size.X,
				Y = CommentData.Size.Y,
			},
		})
	end
	return Serialized
end

local function DeserializeComments(SerializedComments: { any }?): { Types.CommentData }
	if not SerializedComments then
		return {}
	end

	local Comments: { Types.CommentData } = {}
	for _, Data in SerializedComments do
		local Color = Comment.DefaultColor
		if Data.Color then
			Color = Color3.new(Data.Color.R or 0, Data.Color.G or 0, Data.Color.B or 0)
		end

		local Position = Vector2.zero
		if Data.Position then
			Position = Vector2.new(Data.Position.X or 0, Data.Position.Y or 0)
		end

		local Size = Vector2.new(300, 150)
		if Data.Size then
			Size = Vector2.new(Data.Size.X or 300, Data.Size.Y or 150)
		end

		table.insert(Comments, {
			CommentId = Data.CommentId or HttpService:GenerateGUID(false),
			Title = Data.Title or "Comment",
			Text = Data.Text or "",
			Color = Color,
			Position = Position,
			Size = Size,
		})
	end
	return Comments
end

local function SerializeNode(NodeData: Types.NodeInstance): any
	local Node: any = {
		NodeId = NodeData.NodeId,
		BlockType = NodeData.BlockType,
		EditorPosition = {
			X = NodeData.Position.X,
			Y = NodeData.Position.Y,
		},
	}

	if NodeData.BlockType == "BranchStart" then
		return Node
	end

	local Block = NodeFactory.NodeToBlock(NodeData)
	if Block then
		for Key, Value in Block do
			if Key ~= "BlockType" and Key ~= "BlockId" and Key ~= "EditorPosition" then
				Node[Key] = Value
			end
		end
	end

	return Node
end

local function SerializeWire(WireData: Types.WireInstance): any
	return {
		WireId = WireData.WireId,
		FromNode = WireData.FromNodeId,
		FromPort = WireData.FromPortName,
		ToNode = WireData.ToNodeId,
		ToPort = WireData.ToPortName,
	}
end

local function SerializeBranch(Branch: Types.BranchData): any
	local Nodes: { [string]: any } = {}
	local Wires: { any } = {}

	for _, NodeData in Branch.Nodes do
		local SerializedNode = SerializeNode(NodeData)
		Nodes[NodeData.NodeId] = SerializedNode
	end

	for _, WireData in Branch.Wires do
		local SerializedWire = SerializeWire(WireData)
		table.insert(Wires, SerializedWire)
	end

	return {
		Entry = Branch.IsEntry,
		Nodes = Nodes,
		Wires = Wires,
	}
end

function ActionSerializer.Export(State: Types.EditorState): any
	local ActionData: any = {
		ActionId = State.ActionId,
		DisplayName = State.DisplayName,
		IsPlayerMade = true,
		Branches = {},
	}

	local EditorComments: { [string]: any } = {}

	for _, Branch in State.Branches do
		ActionData.Branches[Branch.BranchName] = SerializeBranch(Branch)

		if Branch.Comments and #Branch.Comments > 0 then
			EditorComments[Branch.BranchName] = SerializeComments(Branch.Comments)
		end
	end

	if next(EditorComments) then
		ActionData.EditorData = {
			Comments = EditorComments,
		}
	end

	return ActionData
end

local function DeserializeNode(NodeId: string, NodeData: any): Types.NodeInstance
	local Position = Vector2.new(100, 0)
	if NodeData.EditorPosition then
		Position = Vector2.new(
			NodeData.EditorPosition.X or 100,
			NodeData.EditorPosition.Y or 0
		)
	end

	if NodeData.BlockType == "BranchStart" then
		return {
			NodeId = NodeId,
			BlockType = "BranchStart",
			Position = Position,
			Properties = {},
			Block = nil,
		}
	end

	local Block: any = {
		BlockType = NodeData.BlockType,
		BlockId = NodeId,
	}

	for Key, Value in NodeData do
		if Key ~= "NodeId" and Key ~= "BlockType" and Key ~= "EditorPosition" then
			Block[Key] = Value
		end
	end

	return NodeFactory.BlockToNode(Block, Position)
end

local function DeserializeWire(WireData: any): Types.WireInstance
	return {
		WireId = WireData.WireId or HttpService:GenerateGUID(false),
		FromNodeId = WireData.FromNode or "",
		FromPortName = WireData.FromPort or "",
		ToNodeId = WireData.ToNode or "",
		ToPortName = WireData.ToPort or "",
		WireType = WireData.WireType or "Flow",
	}
end

local function DeserializeBranch(BranchName: string, BranchData: any, Comments: { Types.CommentData }?): Types.BranchData
	local BranchId = HttpService:GenerateGUID(false)
	local Nodes: { Types.NodeInstance } = {}
	local Wires: { Types.WireInstance } = {}

	if BranchData.Nodes then
		for NodeId, NodeData in BranchData.Nodes do
			local Node = DeserializeNode(NodeId, NodeData)
			table.insert(Nodes, Node)
		end
	end

	if BranchData.Wires then
		for _, WireData in BranchData.Wires do
			local Wire = DeserializeWire(WireData)
			table.insert(Wires, Wire)
		end
	end

	return {
		BranchId = BranchId,
		BranchName = BranchName,
		IsEntry = BranchData.Entry == true,
		Nodes = Nodes,
		Wires = Wires,
		Comments = Comments or {},
		Position = Vector2.zero,
	}
end

local function IsLegacyFormat(ActionData: any): boolean
	if ActionData.Timeline then
		return true
	end

	if ActionData.Branches then
		for _, BranchData in ActionData.Branches do
			if BranchData.Timeline and not BranchData.Nodes then
				return true
			end
		end
	end

	return false
end

local function ImportLegacy(ActionData: any): Types.EditorState
	local State: Types.EditorState = {
		ActionId = ActionData.ActionId or "",
		DisplayName = ActionData.DisplayName or "Imported Action",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		SelectedCommentId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	local EditorData = ActionData.EditorData or {}
	local EditorWires = EditorData.Wires or {}
	local EditorComments = EditorData.Comments or {}
	local EditorBranchStarts = EditorData.BranchStarts or {}

	local function CreateBranchStartNode(BranchName: string, FallbackX: number): Types.NodeInstance
		local SavedData = EditorBranchStarts[BranchName]

		local Position = Vector2.new(FallbackX, 0)
		local NodeId = HttpService:GenerateGUID(false)

		if SavedData then
			if SavedData.Position then
				Position = Vector2.new(SavedData.Position.X or FallbackX, SavedData.Position.Y or 0)
			end
			if SavedData.NodeId then
				NodeId = SavedData.NodeId
			end
		end

		return {
			NodeId = NodeId,
			BlockType = "BranchStart",
			Position = Position,
			Properties = {},
			Block = nil,
		}
	end

	local function DeserializeLegacyWires(SerializedWires: { any }?): { Types.WireInstance }
		if not SerializedWires then
			return {}
		end

		local Wires: { Types.WireInstance } = {}
		for _, Data in SerializedWires do
			table.insert(Wires, {
				WireId = Data.WireId or HttpService:GenerateGUID(false),
				FromNodeId = Data.FromNodeId or "",
				FromPortName = Data.FromPortName or "",
				ToNodeId = Data.ToNodeId or "",
				ToPortName = Data.ToPortName or "",
				WireType = Data.WireType or "Flow",
			})
		end
		return Wires
	end

	if ActionData.Timeline then
		local BranchId = HttpService:GenerateGUID(false)
		local Nodes: { Types.NodeInstance } = {}
		local FallbackPositionX = 100

		local BranchStartNode = CreateBranchStartNode("Main", 100)
		table.insert(Nodes, BranchStartNode)
		FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40

		for _, Block in ActionData.Timeline do
			local FallbackPosition = Vector2.new(FallbackPositionX, 0)
			local NodeData = NodeFactory.BlockToNode(Block, FallbackPosition)
			table.insert(Nodes, NodeData)
			FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40
		end

		local BranchWires = DeserializeLegacyWires(EditorWires["Main"] or EditorWires[1])
		local BranchComments = DeserializeComments(EditorComments["Main"])

		State.Branches[BranchId] = {
			BranchId = BranchId,
			BranchName = "Main",
			IsEntry = true,
			Nodes = Nodes,
			Wires = BranchWires,
			Comments = BranchComments,
			Position = Vector2.zero,
		}
	elseif ActionData.Branches then
		for BranchName, BranchData in ActionData.Branches do
			local BranchId = HttpService:GenerateGUID(false)
			local Nodes: { Types.NodeInstance } = {}
			local FallbackPositionX = 100

			local BranchStartNode = CreateBranchStartNode(BranchName, 100)
			table.insert(Nodes, BranchStartNode)
			FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40

			if BranchData.Timeline then
				for _, Block in BranchData.Timeline do
					local FallbackPosition = Vector2.new(FallbackPositionX, 0)
					local NodeData = NodeFactory.BlockToNode(Block, FallbackPosition)
					table.insert(Nodes, NodeData)
					FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40
				end
			end

			local BranchWires = DeserializeLegacyWires(EditorWires[BranchName])
			local BranchComments = DeserializeComments(EditorComments[BranchName])

			State.Branches[BranchId] = {
				BranchId = BranchId,
				BranchName = BranchName,
				IsEntry = BranchData.Entry == true,
				Nodes = Nodes,
				Wires = BranchWires,
				Comments = BranchComments,
				Position = Vector2.zero,
			}
		end
	end

	return State
end

function ActionSerializer.Import(ActionData: any): Types.EditorState
	if IsLegacyFormat(ActionData) then
		return ImportLegacy(ActionData)
	end

	local State: Types.EditorState = {
		ActionId = ActionData.ActionId or "",
		DisplayName = ActionData.DisplayName or "Imported Action",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		SelectedCommentId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	local EditorData = ActionData.EditorData or {}
	local EditorComments = EditorData.Comments or {}

	if ActionData.Branches then
		for BranchName, BranchData in ActionData.Branches do
			local Comments = DeserializeComments(EditorComments[BranchName])
			local Branch = DeserializeBranch(BranchName, BranchData, Comments)
			State.Branches[Branch.BranchId] = Branch
		end
	end

	return State
end

function ActionSerializer.ToJson(ActionData: any): string
	return HttpService:JSONEncode(ActionData)
end

function ActionSerializer.FromJson(JsonString: string): any?
	local Success, Result = pcall(function()
		return HttpService:JSONDecode(JsonString)
	end)

	if Success then
		return Result
	end

	return nil
end

return ActionSerializer