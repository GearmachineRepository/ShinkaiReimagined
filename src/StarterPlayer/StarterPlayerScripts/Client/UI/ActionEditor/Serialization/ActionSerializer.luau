--!strict

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent.Types)
local Theme = require(script.Parent.Parent.Theme)
local Comment = require(script.Parent.Parent.Graph.Comment)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)

local ActionSerializer = {}

local function SerializeWires(Wires: { Types.WireInstance }): { any }
	local Serialized = {}
	for _, WireData in Wires do
		table.insert(Serialized, {
			WireId = WireData.WireId,
			FromNodeId = WireData.FromNodeId,
			FromPortName = WireData.FromPortName,
			ToNodeId = WireData.ToNodeId,
			ToPortName = WireData.ToPortName,
			WireType = WireData.WireType,
		})
	end
	return Serialized
end

local function DeserializeWires(SerializedWires: { any }?): { Types.WireInstance }
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

function ActionSerializer.Import(ActionData: any): Types.EditorState
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

		local BranchWires = DeserializeWires(EditorWires["Main"] or EditorWires[1])
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

			local BranchWires = DeserializeWires(EditorWires[BranchName])
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

function ActionSerializer.Export(State: Types.EditorState): any
	local ActionData: any = {
		ActionId = State.ActionId,
		DisplayName = State.DisplayName,
		IsPlayerMade = true,
	}

	local BranchCount = 0
	for _ in State.Branches do
		BranchCount = BranchCount + 1
	end

	local EditorWires: { [string]: any } = {}
	local EditorComments: { [string]: any } = {}
	local EditorBranchStarts: { [string]: any } = {}

	if BranchCount == 1 then
		for _, Branch in State.Branches do
			if Branch.IsEntry then
				local Timeline = {}
				for _, NodeData in Branch.Nodes do
					if NodeData.BlockType == "BranchStart" then
						EditorBranchStarts["Main"] = {
							NodeId = NodeData.NodeId,
							Position = {
								X = NodeData.Position.X,
								Y = NodeData.Position.Y,
							},
						}
					else
						local Block = NodeFactory.NodeToBlock(NodeData)
						table.insert(Timeline, Block)
					end
				end
				ActionData.Timeline = Timeline
				EditorWires["Main"] = SerializeWires(Branch.Wires)
				EditorComments["Main"] = SerializeComments(Branch.Comments)
				break
			end
		end
	else
		ActionData.Branches = {}
		for _, Branch in State.Branches do
			local Timeline = {}
			for _, NodeData in Branch.Nodes do
				if NodeData.BlockType == "BranchStart" then
					EditorBranchStarts[Branch.BranchName] = {
						NodeId = NodeData.NodeId,
						Position = {
							X = NodeData.Position.X,
							Y = NodeData.Position.Y,
						},
					}
				else
					local Block = NodeFactory.NodeToBlock(NodeData)
					table.insert(Timeline, Block)
				end
			end
			ActionData.Branches[Branch.BranchName] = {
				Entry = Branch.IsEntry,
				Timeline = Timeline,
			}
			EditorWires[Branch.BranchName] = SerializeWires(Branch.Wires)
			EditorComments[Branch.BranchName] = SerializeComments(Branch.Comments)
		end
	end

	ActionData.EditorData = {
		Wires = EditorWires,
		Comments = EditorComments,
		BranchStarts = EditorBranchStarts,
	}

	return ActionData
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