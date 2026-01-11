--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)
local Theme = require(script.Parent.Parent.Theme)
local EditorState = require(script.Parent.EditorState)
local BranchManager = require(script.Parent.BranchManager)
local CommentGraph = require(script.Parent.Parent.Graph.Comment)

local CommentManager = {}

local CommentAddedSignal = Signal.new()
local CommentDeletedSignal = Signal.new()
local CommentMovedSignal = Signal.new()
local CommentResizedSignal = Signal.new()
local CommentPropertyChangedSignal = Signal.new()

local NODE_SPAWN_OFFSET = 40
local SpawnCounter = 0

local CanvasSize: Vector2 = Vector2.new(800, 600)
local CanvasToWorldFunc: ((Vector2) -> Vector2)? = nil

function CommentManager.SetCanvasSize(Size: Vector2)
	CanvasSize = Size
end

function CommentManager.SetCanvasToWorldFunction(Func: (Vector2) -> Vector2)
	CanvasToWorldFunc = Func
end

function CommentManager.ResetSpawnCounter()
	SpawnCounter = 0
end

function CommentManager.SyncSpawnCounter(Counter: number)
	SpawnCounter = Counter
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

function CommentManager.Add(Position: Vector2?, Title: string?, Color: Color3?): Types.CommentData?
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		local BranchId = BranchManager.EnsureDefaultBranch()
		BranchManager.Select(BranchId)
		Branch = BranchManager.GetCurrent()
	end

	if not Branch then
		return nil
	end

	local Comments = Branch.Comments or {}

	local SpawnPosition = Position or GetSpawnPosition()

	local CommentData: Types.CommentData = {
		CommentId = HttpService:GenerateGUID(false),
		Title = Title or "Comment",
		Text = "",
		Color = Color or CommentGraph.DefaultColor,
		Position = SpawnPosition,
		Size = Vector2.new(300, 150),
	}

	table.insert(Comments, CommentData)
	EditorState.MarkDirty()
	CommentAddedSignal:Fire(CommentData)

	return CommentData
end

function CommentManager.Delete(CommentId: string): boolean
	local Branch = BranchManager.GetCurrent()
	if not Branch or not Branch.Comments then
		return false
	end

	for Index, CommentData in Branch.Comments do
		if CommentData.CommentId == CommentId then
			table.remove(Branch.Comments, Index)

			local SelectedCommentId = EditorState.GetSelectedCommentId()
			if SelectedCommentId == CommentId then
				EditorState.SetSelectedCommentId(nil)
			end

			EditorState.MarkDirty()
			CommentDeletedSignal:Fire(CommentId)
			return true
		end
	end

	return false
end

function CommentManager.Select(CommentId: string?): boolean
	if CommentId then
		local CommentData = CommentManager.GetById(CommentId)
		if not CommentData then
			return false
		end
	end

	EditorState.SetSelectedCommentId(CommentId)
	return true
end

function CommentManager.Move(CommentId: string, Position: Vector2): boolean
	local CommentData = CommentManager.GetById(CommentId)
	if not CommentData then
		return false
	end

	CommentData.Position = Position
	EditorState.MarkDirty()
	CommentMovedSignal:Fire(CommentId, Position)

	return true
end

function CommentManager.Resize(CommentId: string, Size: Vector2): boolean
	local CommentData = CommentManager.GetById(CommentId)
	if not CommentData then
		return false
	end

	CommentData.Size = Size
	EditorState.MarkDirty()
	CommentResizedSignal:Fire(CommentId, Size)

	return true
end

function CommentManager.SetTitle(CommentId: string, Title: string): boolean
	local CommentData = CommentManager.GetById(CommentId)
	if not CommentData then
		return false
	end

	CommentData.Title = Title
	EditorState.MarkDirty()
	CommentPropertyChangedSignal:Fire(CommentId, "Title", Title)

	return true
end

function CommentManager.SetText(CommentId: string, Text: string): boolean
	local CommentData = CommentManager.GetById(CommentId)
	if not CommentData then
		return false
	end

	CommentData.Text = Text
	EditorState.MarkDirty()
	CommentPropertyChangedSignal:Fire(CommentId, "Text", Text)

	return true
end

function CommentManager.SetColor(CommentId: string, Color: Color3): boolean
	local CommentData = CommentManager.GetById(CommentId)
	if not CommentData then
		return false
	end

	CommentData.Color = Color
	EditorState.MarkDirty()
	CommentPropertyChangedSignal:Fire(CommentId, "Color", Color :: any)

	return true
end

function CommentManager.GetById(CommentId: string): Types.CommentData?
	local Branch = BranchManager.GetCurrent()
	if not Branch or not Branch.Comments then
		return nil
	end

	for _, CommentData in Branch.Comments do
		if CommentData.CommentId == CommentId then
			return CommentData
		end
	end

	return nil
end

function CommentManager.GetSelected(): Types.CommentData?
	local SelectedCommentId = EditorState.GetSelectedCommentId()
	if not SelectedCommentId then
		return nil
	end

	return CommentManager.GetById(SelectedCommentId)
end

function CommentManager.GetAll(): { Types.CommentData }
	local Branch = BranchManager.GetCurrent()
	if not Branch or not Branch.Comments then
		return {}
	end

	return Branch.Comments
end

CommentManager.CommentAdded = CommentAddedSignal
CommentManager.CommentDeleted = CommentDeletedSignal
CommentManager.CommentMoved = CommentMovedSignal
CommentManager.CommentResized = CommentResizedSignal
CommentManager.CommentPropertyChanged = CommentPropertyChangedSignal

return CommentManager