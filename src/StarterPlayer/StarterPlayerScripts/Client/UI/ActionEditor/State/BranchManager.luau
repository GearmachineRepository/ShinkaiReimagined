--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)
local EditorState = require(script.Parent.EditorState)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)

local BranchManager = {}

local BranchCreatedSignal = Signal.new()
local BranchDeletedSignal = Signal.new()
local BranchRenamedSignal = Signal.new()
local BranchListChangedSignal = Signal.new()

local BRANCH_START_POSITION = Vector2.new(100, 100)

function BranchManager.Create(BranchName: string): string
	local Branches = EditorState.GetBranches()
	local BranchId = HttpService:GenerateGUID(false)
	local IsEntry = next(Branches) == nil

	local BranchStartNode = NodeFactory.CreateNodeInstance("BranchStart", BRANCH_START_POSITION)

	local BranchData: Types.BranchData = {
		BranchId = BranchId,
		BranchName = BranchName,
		IsEntry = IsEntry,
		Nodes = { BranchStartNode },
		Wires = {},
		Comments = {},
		Position = Vector2.zero,
		Collapsed = false,
	}

	EditorState.SetBranch(BranchId, BranchData)
	BranchCreatedSignal:Fire(BranchId, BranchData)
	BranchListChangedSignal:Fire(EditorState.GetBranches())

	return BranchId
end

function BranchManager.Delete(BranchId: string): boolean
	local Branch = EditorState.GetBranch(BranchId)
	if not Branch then
		return false
	end

	local SelectedBranchId = EditorState.GetSelectedBranchId()
	if SelectedBranchId == BranchId then
		EditorState.SetSelectedBranchId(nil)
		EditorState.ClearSelection()
	end

	EditorState.SetBranch(BranchId, nil)
	BranchDeletedSignal:Fire(BranchId)
	BranchListChangedSignal:Fire(EditorState.GetBranches())

	return true
end

function BranchManager.Select(BranchId: string): boolean
	local Branch = EditorState.GetBranch(BranchId)
	if not Branch then
		return false
	end

	EditorState.SetSelectedBranchId(BranchId)
	EditorState.ClearSelection()

	return true
end

function BranchManager.SelectFirst(): string?
	local Branches = EditorState.GetBranches()
	for BranchId in Branches do
		BranchManager.Select(BranchId)
		return BranchId
	end
	return nil
end

function BranchManager.Rename(BranchId: string, NewName: string): boolean
	local Branch = EditorState.GetBranch(BranchId)
	if not Branch then
		return false
	end

	local OldName = Branch.BranchName
	Branch.BranchName = NewName
	EditorState.MarkDirty()
	BranchRenamedSignal:Fire(BranchId, NewName, OldName)
	BranchListChangedSignal:Fire(EditorState.GetBranches())

	return true
end

function BranchManager.SetEntry(BranchId: string): boolean
	local TargetBranch = EditorState.GetBranch(BranchId)
	if not TargetBranch then
		return false
	end

	local Branches = EditorState.GetBranches()
	for _, Branch in Branches do
		Branch.IsEntry = Branch.BranchId == BranchId
	end

	EditorState.MarkDirty()
	BranchListChangedSignal:Fire(Branches)

	return true
end

function BranchManager.GetCurrent(): Types.BranchData?
	return EditorState.GetCurrentBranch()
end

function BranchManager.GetById(BranchId: string): Types.BranchData?
	return EditorState.GetBranch(BranchId)
end

function BranchManager.GetAll(): { [string]: Types.BranchData }
	return EditorState.GetBranches()
end

function BranchManager.GetBranchNames(): { string }
	local Names: { string } = {}
	local Branches = EditorState.GetBranches()
	for _, Branch in Branches do
		table.insert(Names, Branch.BranchName)
	end
	return Names
end

function BranchManager.GetBranchByName(BranchName: string): Types.BranchData?
	local Branches = EditorState.GetBranches()
	for _, Branch in Branches do
		if Branch.BranchName == BranchName then
			return Branch
		end
	end
	return nil
end

function BranchManager.GetCount(): number
	local Count = 0
	for _ in EditorState.GetBranches() do
		Count = Count + 1
	end
	return Count
end

function BranchManager.EnsureDefaultBranch(): string
	local Branches = EditorState.GetBranches()
	if next(Branches) == nil then
		return BranchManager.Create("Main")
	end

	for BranchId in Branches do
		return BranchId
	end

	return BranchManager.Create("Main")
end

BranchManager.BranchCreated = BranchCreatedSignal
BranchManager.BranchDeleted = BranchDeletedSignal
BranchManager.BranchRenamed = BranchRenamedSignal
BranchManager.BranchListChanged = BranchListChangedSignal

return BranchManager