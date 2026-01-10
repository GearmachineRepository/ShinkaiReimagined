--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)

local Client = LocalPlayer.PlayerScripts:WaitForChild("Client")
local SkillEditor = require(Client.UI.SkillEditor)

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
local CachedSkills: { [string]: any } = {}

local TOGGLE_KEY = Enum.KeyCode.F4

local function CreateScreenGui(): ScreenGui
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "SkillEditorGui"
	Gui.ResetOnSpawn = false
	Gui.IgnoreGuiInset = true
	Gui.DisplayOrder = 100
	Gui.Enabled = false
	Gui.Parent = PlayerGui
	return Gui
end

local function OnSave(SkillData: any)
	if not SkillData then
		return
	end

	local SkillId = SkillData.SkillId
	local IsNewSkill = not SkillId or SkillId == "" or not CachedSkills[SkillId]

	if IsNewSkill then
		Packets.PlayerSkillCreate:Fire(SkillData)
	else
		Packets.PlayerSkillUpdate:Fire(SkillData)
	end

	SkillEditorController.SkillSaved:Fire(SkillData)
end

local function OnTest(SkillData: any)
	if not SkillData then
		return
	end

	local SkillId = SkillData.SkillId
	local IsNewSkill = not SkillId or SkillId == "" or not CachedSkills[SkillId]

	if IsNewSkill then
		Packets.PlayerSkillCreate:Fire(SkillData)
	else
		Packets.PlayerSkillUpdate:Fire(SkillData)
	end

	SkillEditorController.SkillTested:Fire(SkillData)
end

local function OnLoad()
	-- PlayerSkillSync is sent automatically on join
	-- This callback can open a skill picker modal
end

function SkillEditorController.Init()
	ControllerTrove = Trove.new()
	ScreenGui = CreateScreenGui()
	ControllerTrove:Add(ScreenGui)
end

function SkillEditorController.Start()
    local EditorValues = {
		Parent = ScreenGui,
		OnSave = OnSave,
		OnTest = OnTest,
		OnLoad = OnLoad,
	} :: any
	EditorInstance = SkillEditor.Create(EditorValues)
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

	ControllerTrove:Connect(Packets.PlayerSkillSync.OnClientEvent :: any, function(Skills: { [string]: any })
		CachedSkills = Skills
	end)

	ControllerTrove:Connect(Packets.PlayerSkillAdded.OnClientEvent :: any, function(SkillId: string, SkillData: any)
		CachedSkills[SkillId] = SkillData
		if EditorInstance then
			local CurrentData = EditorInstance.GetSkillData()
			if CurrentData and (not CurrentData.SkillId or CurrentData.SkillId == "") then
				SkillData.SkillId = SkillId
				EditorInstance.LoadSkill(SkillData)
			end
		end
	end)

	ControllerTrove:Connect(Packets.PlayerSkillRemoved.OnClientEvent :: any, function(SkillId: string)
		CachedSkills[SkillId] = nil
	end)

	ControllerTrove:Connect(Packets.PlayerSkillCreateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
		if Success then
			print("[SkillEditor] Skill created:", Result)
		else
			warn("[SkillEditor] Failed to create skill:", Result)
		end
	end)

	ControllerTrove:Connect(Packets.PlayerSkillUpdateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
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

function SkillEditorController.GetCachedSkills(): { [string]: any }
	return CachedSkills
end

function SkillEditorController.GetCachedSkill(SkillId: string): any?
	return CachedSkills[SkillId]
end

function SkillEditorController.LoadSkillById(SkillId: string)
	local SkillData = CachedSkills[SkillId]
	if SkillData and EditorInstance then
		EditorInstance.LoadSkill(SkillData)
	end
end

return SkillEditorController