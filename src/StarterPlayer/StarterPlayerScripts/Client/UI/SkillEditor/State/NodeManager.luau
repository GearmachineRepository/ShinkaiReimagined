--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)
local Theme = require(script.Parent.Parent.Theme)
local EditorState = require(script.Parent.EditorState)
local BranchManager = require(script.Parent.BranchManager)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)

local NodeManager = {}

local NodeAddedSignal = Signal.new()
local NodeDeletedSignal = Signal.new()
local NodeMovedSignal = Signal.new()
local NodePropertyChangedSignal = Signal.new()

local SpawnCounter = 0
local NODE_SPAWN_OFFSET = 40

local CanvasSize: Vector2 = Vector2.new(800, 600)
local CanvasToWorldFunc: ((Vector2) -> Vector2)? = nil

function NodeManager.SetCanvasSize(Size: Vector2)
	CanvasSize = Size
end

function NodeManager.SetCanvasToWorldFunction(Func: (Vector2) -> Vector2)
	CanvasToWorldFunc = Func
end

function NodeManager.ResetSpawnCounter()
	SpawnCounter = 0
end

local function GetSpawnPosition(): Vector2
	local CanvasCenter: Vector2

	if CanvasToWorldFunc then
		CanvasCenter = CanvasToWorldFunc(Vector2.new(CanvasSize.X / 2, CanvasSize.Y / 2))
	else
		CanvasCenter = Vector2.new(CanvasSize.X / 2, CanvasSize.Y / 2)
	end

	local OffsetX = (SpawnCounter % 5) * (Theme.Sizes.NodeWidth + NODE_SPAWN_OFFSET)
	local OffsetY = math.floor(SpawnCounter / 5) * 100

	SpawnCounter = SpawnCounter + 1

	return CanvasCenter + Vector2.new(OffsetX - 200, OffsetY - 100)
end

function NodeManager.Add(BlockType: string, Position: Vector2?): Types.NodeInstance?
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		local BranchId = BranchManager.EnsureDefaultBranch()
		BranchManager.Select(BranchId)
		Branch = BranchManager.GetCurrent()
	end

	if not Branch then
		return nil
	end

	local SpawnPosition = Position or GetSpawnPosition()
	local NodeData = NodeFactory.CreateNodeInstance(BlockType, SpawnPosition)
	table.insert(Branch.Nodes, NodeData)

	EditorState.MarkDirty()
	NodeAddedSignal:Fire(NodeData)

	return NodeData
end

function NodeManager.Delete(NodeId: string): boolean
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return false
	end

	local NodeData = NodeManager.GetById(NodeId)
	if not NodeData then
		return false
	end

	if NodeData.BlockType == "BranchStart" then
		return false
	end

	for Index, Node in Branch.Nodes do
		if Node.NodeId == NodeId then
			table.remove(Branch.Nodes, Index)
			break
		end
	end

	local SelectedNodeId = EditorState.GetSelectedNodeId()
	if SelectedNodeId == NodeId then
		EditorState.SetSelectedNodeId(nil)
	end

	EditorState.MarkDirty()
	NodeDeletedSignal:Fire(NodeId)

	return true
end

function NodeManager.Select(NodeId: string?): boolean
	if NodeId then
		local NodeData = NodeManager.GetById(NodeId)
		if not NodeData then
			return false
		end
	end

	EditorState.SetSelectedNodeId(NodeId)
	return true
end

function NodeManager.Move(NodeId: string, Position: Vector2): boolean
	local NodeData = NodeManager.GetById(NodeId)
	if not NodeData then
		return false
	end

	NodeData.Position = Position
	EditorState.MarkDirty()
	NodeMovedSignal:Fire(NodeId, Position)

	return true
end

function NodeManager.SetProperty(NodeId: string, Key: string, Value: any): boolean
	local NodeData = NodeManager.GetById(NodeId)
	if not NodeData then
		return false
	end

	NodeData.Properties[Key] = Value
	EditorState.MarkDirty()
	NodePropertyChangedSignal:Fire(NodeId, Key, Value)

	return true
end

function NodeManager.GetById(NodeId: string): Types.NodeInstance?
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return nil
	end

	for _, NodeData in Branch.Nodes do
		if NodeData.NodeId == NodeId then
			return NodeData
		end
	end

	return nil
end

function NodeManager.GetSelected(): Types.NodeInstance?
	local SelectedNodeId = EditorState.GetSelectedNodeId()
	if not SelectedNodeId then
		return nil
	end

	return NodeManager.GetById(SelectedNodeId)
end

function NodeManager.GetAll(): { Types.NodeInstance }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	return Branch.Nodes
end

function NodeManager.GetByBlockType(BlockType: string): { Types.NodeInstance }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	local Nodes: { Types.NodeInstance } = {}
	for _, NodeData in Branch.Nodes do
		if NodeData.BlockType == BlockType then
			table.insert(Nodes, NodeData)
		end
	end

	return Nodes
end

function NodeManager.IsBranchStart(NodeId: string): boolean
	local NodeData = NodeManager.GetById(NodeId)
	if not NodeData then
		return false
	end

	return NodeData.BlockType == "BranchStart"
end

function NodeManager.CanDelete(NodeId: string): boolean
	return not NodeManager.IsBranchStart(NodeId)
end

NodeManager.NodeAdded = NodeAddedSignal
NodeManager.NodeDeleted = NodeDeletedSignal
NodeManager.NodeMoved = NodeMovedSignal
NodeManager.NodePropertyChanged = NodePropertyChangedSignal

return NodeManager