--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)

local Client = LocalPlayer.PlayerScripts:WaitForChild("Client")
local SkillEditor = require(Client.UI.SkillEditor)
local PlayerSkillController = require(Client.Controllers.PlayerSkillController)

local Trove = Packages.Trove
local Signal = Packages.Signal

local SkillEditorController = {}

SkillEditorController.Dependencies = { "PlayerSkillController" }

SkillEditorController.EditorOpened = Signal.new()
SkillEditorController.EditorClosed = Signal.new()
SkillEditorController.SkillSaved = Signal.new()
SkillEditorController.SkillTested = Signal.new()

local ControllerTrove: typeof(Trove.new()) = nil :: any
local ScreenGui: ScreenGui = nil :: any
local EditorInstance: SkillEditor.EditorWindowInstance? = nil
local IsOpen = false

local TOGGLE_KEY = Enum.KeyCode.T

local function CreateScreenGui(): ScreenGui
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "SkillEditorGui"
	Gui.ResetOnSpawn = false
	Gui.IgnoreGuiInset = false
	Gui.DisplayOrder = 100
	Gui.Enabled = false
	Gui.Parent = PlayerGui
	return Gui
end

local PreviousMouseBehavior: Enum.MouseBehavior = Enum.MouseBehavior.Default

local function LockMouse()
	PreviousMouseBehavior = UserInputService.MouseBehavior
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local function UnlockMouse()
	UserInputService.MouseBehavior = PreviousMouseBehavior
end

local function OnSave(SkillData: any): boolean
	if not SkillData then
		return false
	end

	local SkillId = SkillData.SkillId
	local IsNewSkill = not SkillId or SkillId == "" or not PlayerSkillController.GetSkill(SkillId)

	local Success: boolean
	if IsNewSkill then
		Success = PlayerSkillController.CreateSkill(SkillData)
	else
		Success = PlayerSkillController.UpdateSkill(SkillData)
	end

	if Success then
		SkillEditorController.SkillSaved:Fire(SkillData)
	end

	return Success
end

local function OnTest(SkillData: any)
	if not SkillData then
		return
	end

	local SkillId = SkillData.SkillId
	local IsNewSkill = not SkillId or SkillId == "" or not PlayerSkillController.GetSkill(SkillId)

	if IsNewSkill then
		PlayerSkillController.CreateSkill(SkillData)
	else
		PlayerSkillController.UpdateSkill(SkillData)
	end

	SkillEditorController.SkillTested:Fire(SkillData)
end

local function OnLoad(SkillId: string): any?
	return PlayerSkillController.GetSkill(SkillId)
end

local function GetSkillsList(): { { Id: string, Name: string } }
	local AllSkills = PlayerSkillController.GetAllSkills()
	local List = {}

	for SkillId, SkillData in AllSkills do
		table.insert(List, {
			Id = SkillId,
			Name = SkillData.DisplayName or SkillId,
		})
	end

	table.sort(List, function(A, B)
		return A.Name < B.Name
	end)

	return List
end

function SkillEditorController.Init()
	ControllerTrove = Trove.new()
	ScreenGui = CreateScreenGui()
	ControllerTrove:Add(ScreenGui)
end

function SkillEditorController.Start()
	EditorInstance = SkillEditor.Create({
		Parent = ScreenGui,
		OnSave = OnSave,
		OnTest = OnTest,
		OnLoad = OnLoad,
		GetSkillsList = GetSkillsList,
	} :: any)

	ControllerTrove:Add(function()
		if EditorInstance then
			EditorInstance.Destroy()
			EditorInstance = nil
		end
	end)

	ControllerTrove:Connect(UserInputService.InputBegan, function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then
			return
		end

		if Input.KeyCode == TOGGLE_KEY then
			SkillEditorController.Toggle()
		end
	end)

	ControllerTrove:Connect(PlayerSkillController.SkillAdded :: any, function(SkillId: string, _SkillData: any)
		if EditorInstance then
			local CurrentSkillId = EditorInstance.GetSkillId()
			if not CurrentSkillId or CurrentSkillId == "" then
				EditorInstance.SetSkillId(SkillId)
			end
		end
	end)

	ControllerTrove:Connect(PlayerSkillController.CreateResult :: any, function(Success: boolean, Result: string)
		if Success then
			print("[SkillEditor] Skill created:", Result)
		else
			warn("[SkillEditor] Failed to create skill:", Result)
		end
	end)

	ControllerTrove:Connect(PlayerSkillController.UpdateResult :: any, function(Success: boolean, Result: string)
		if Success then
			print("[SkillEditor] Skill updated:", Result)
		else
			warn("[SkillEditor] Failed to update skill:", Result)
		end
	end)
end

function SkillEditorController.Stop()
	ControllerTrove:Destroy()
end

function SkillEditorController.Open()
	if IsOpen then
		return
	end

	IsOpen = true
	LockMouse()
	ScreenGui.Enabled = true

	if EditorInstance then
		EditorInstance.SetVisible(true)
	end

	SkillEditorController.EditorOpened:Fire()
end

function SkillEditorController.Close()
	if not IsOpen then
		return
	end

	IsOpen = false
	UnlockMouse()
	ScreenGui.Enabled = false

	if EditorInstance then
		EditorInstance.SetVisible(false)
	end

	SkillEditorController.EditorClosed:Fire()
end

function SkillEditorController.Toggle()
	if IsOpen then
		SkillEditorController.Close()
	else
		SkillEditorController.Open()
	end
end

function SkillEditorController.IsOpen(): boolean
	return IsOpen
end

function SkillEditorController.LoadSkill(SkillData: any)
	if EditorInstance then
		EditorInstance.LoadSkill(SkillData)
	end
end

function SkillEditorController.LoadSkillById(SkillId: string)
	local SkillData = PlayerSkillController.GetSkill(SkillId)
	if SkillData and EditorInstance then
		EditorInstance.LoadSkill(SkillData)
	end
end

function SkillEditorController.NewSkill()
	if EditorInstance then
		EditorInstance.NewSkill()
	end
end

function SkillEditorController.GetCurrentSkillData(): any?
	if EditorInstance then
		return EditorInstance.GetSkillData()
	end
	return nil
end

return SkillEditorController