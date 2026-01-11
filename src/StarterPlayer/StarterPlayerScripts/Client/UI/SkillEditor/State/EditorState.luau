--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)

export type State = Types.EditorState

local EditorState = {}

local CurrentState: State = nil :: any
local DirtyChangedSignal = Signal.new()
local BranchSelectedSignal = Signal.new()
local NodeSelectedSignal = Signal.new()
local CommentSelectedSignal = Signal.new()
local StateResetSignal = Signal.new()

local function CreateDefaultState(): State
	return {
		SkillId = "",
		DisplayName = "New Skill",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		SelectedCommentId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}
end

function EditorState.Init()
	CurrentState = CreateDefaultState()
end

function EditorState.Get(): State
	return CurrentState
end

function EditorState.Set(NewState: State)
	CurrentState = NewState
	StateResetSignal:Fire(CurrentState)
end

function EditorState.MarkDirty()
	if not CurrentState.IsDirty then
		CurrentState.IsDirty = true
		DirtyChangedSignal:Fire(true)
	end
end

function EditorState.ClearDirty()
	if CurrentState.IsDirty then
		CurrentState.IsDirty = false
		DirtyChangedSignal:Fire(false)
	end
end

function EditorState.IsDirty(): boolean
	return CurrentState.IsDirty
end

function EditorState.GetSkillId(): string
	return CurrentState.SkillId
end

function EditorState.SetSkillId(SkillId: string)
	CurrentState.SkillId = SkillId
	EditorState.MarkDirty()
end

function EditorState.GetDisplayName(): string
	return CurrentState.DisplayName
end

function EditorState.SetDisplayName(DisplayName: string)
	CurrentState.DisplayName = DisplayName
	EditorState.MarkDirty()
end

function EditorState.GetBranches(): { [string]: Types.BranchData }
	return CurrentState.Branches
end

function EditorState.GetBranch(BranchId: string): Types.BranchData?
	return CurrentState.Branches[BranchId]
end

function EditorState.SetBranch(BranchId: string, BranchData: Types.BranchData?)
	CurrentState.Branches[BranchId] = BranchData :: Types.BranchData
	EditorState.MarkDirty()
end

function EditorState.GetSelectedBranchId(): string?
	return CurrentState.SelectedBranchId
end

function EditorState.SetSelectedBranchId(BranchId: string?)
	local OldBranchId = CurrentState.SelectedBranchId
	CurrentState.SelectedBranchId = BranchId
	if OldBranchId ~= BranchId then
		BranchSelectedSignal:Fire(BranchId, OldBranchId)
	end
end

function EditorState.GetCurrentBranch(): Types.BranchData?
	if not CurrentState.SelectedBranchId then
		return nil
	end
	return CurrentState.Branches[CurrentState.SelectedBranchId]
end

function EditorState.GetSelectedNodeId(): string?
	return CurrentState.SelectedNodeId
end

function EditorState.SetSelectedNodeId(NodeId: string?)
	local OldNodeId = CurrentState.SelectedNodeId
	local OldCommentId = CurrentState.SelectedCommentId
	CurrentState.SelectedNodeId = NodeId
	CurrentState.SelectedCommentId = nil
	if OldCommentId then
		CommentSelectedSignal:Fire(nil, OldCommentId)
	end
	if OldNodeId ~= NodeId then
		NodeSelectedSignal:Fire(NodeId, OldNodeId)
	end
end

function EditorState.GetSelectedCommentId(): string?
	return CurrentState.SelectedCommentId
end

function EditorState.SetSelectedCommentId(CommentId: string?)
	local OldCommentId = CurrentState.SelectedCommentId
	local OldNodeId = CurrentState.SelectedNodeId
	CurrentState.SelectedCommentId = CommentId
	CurrentState.SelectedNodeId = nil
	if OldNodeId then
		NodeSelectedSignal:Fire(nil, OldNodeId)
	end
	if OldCommentId ~= CommentId then
		CommentSelectedSignal:Fire(CommentId, OldCommentId)
	end
end

function EditorState.ClearSelection()
	local OldNodeId = CurrentState.SelectedNodeId
	local OldCommentId = CurrentState.SelectedCommentId
	CurrentState.SelectedNodeId = nil
	CurrentState.SelectedCommentId = nil
	if OldNodeId then
		NodeSelectedSignal:Fire(nil, OldNodeId)
	end
	if OldCommentId then
		CommentSelectedSignal:Fire(nil, OldCommentId)
	end
end

function EditorState.Reset()
	CurrentState = CreateDefaultState()
	StateResetSignal:Fire(CurrentState)
end

EditorState.DirtyChanged = DirtyChangedSignal
EditorState.BranchSelected = BranchSelectedSignal
EditorState.NodeSelected = NodeSelectedSignal
EditorState.CommentSelected = CommentSelectedSignal
EditorState.StateReset = StateResetSignal

return EditorState