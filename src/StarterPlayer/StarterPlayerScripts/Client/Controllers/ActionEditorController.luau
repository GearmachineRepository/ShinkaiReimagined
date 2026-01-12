--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)

local Client = LocalPlayer.PlayerScripts:WaitForChild("Client")
local ActionEditor = require(Client.UI.ActionEditor)
local PlayerActionController = require(Client.Controllers.PlayerActionController)

local Trove = Packages.Trove
local Signal = Packages.Signal

local ActionEditorController = {}

ActionEditorController.Dependencies = { "PlayerActionController" }

ActionEditorController.EditorOpened = Signal.new()
ActionEditorController.EditorClosed = Signal.new()
ActionEditorController.ActionSaved = Signal.new()

local ControllerTrove: typeof(Trove.new()) = nil :: any
local ScreenGui: ScreenGui = nil :: any
local EditorInstance: ActionEditor.EditorWindowInstance? = nil
local IsOpen = false

local TOGGLE_KEY = Enum.KeyCode.T

local function CreateScreenGui(): ScreenGui
	local Gui = Instance.new("ScreenGui")
	Gui.Name = "ActionEditorGui"
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

local function OnSave(ActionData: any): boolean
	if not ActionData then
		return false
	end

	local ActionId = ActionData.ActionId
	local IsNewAction = not ActionId or ActionId == "" or not PlayerActionController.GetAction(ActionId)

	local Success: boolean
	if IsNewAction then
		Success = PlayerActionController.CreateAction(ActionData)
	else
		Success = PlayerActionController.UpdateAction(ActionData)
	end

	if Success then
		ActionEditorController.ActionSaved:Fire(ActionData)
	end

	return Success
end

local function OnTest(ActionData: any)
	if not ActionData then
		return
	end

	local Saved = OnSave(ActionData)
	if Saved then
		print("[ActionEditor] Action saved. Use the Equip Cube in the world to equip it as a tool.")
	end
end

local function OnLoad(ActionId: string): any?
	return PlayerActionController.GetAction(ActionId)
end

local function GetActionsList(): { { Id: string, Name: string } }
	local AllActions = PlayerActionController.GetAllActions()
	local List = {}

	for CurrentActionId, ActionData in AllActions do
		table.insert(List, {
			Id = CurrentActionId,
			Name = ActionData.DisplayName or CurrentActionId,
		})
	end

	table.sort(List, function(A, B)
		return A.Name < B.Name
	end)

	return List
end

function ActionEditorController.Init()
	ControllerTrove = Trove.new()
	ScreenGui = CreateScreenGui()
	ControllerTrove:Add(ScreenGui)
end

function ActionEditorController.Start()
	EditorInstance = ActionEditor.Create({
		Parent = ScreenGui,
		OnSave = OnSave,
		OnTest = OnTest,
		OnLoad = OnLoad,
		GetActionsList = GetActionsList,
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
			ActionEditorController.Toggle()
		end
	end)

	ControllerTrove:Connect(PlayerActionController.ActionAdded :: any, function(CurrentActionId: string, _ActionData: any)
		if EditorInstance then
			local EditorActionId = EditorInstance.GetActionId()
			if not EditorActionId or EditorActionId == "" then
				EditorInstance.SetActionId(CurrentActionId)
			end
		end
	end)

	ControllerTrove:Connect(PlayerActionController.CreateResult :: any, function(Success: boolean, Result: string)
		if Success then
			print("[ActionEditor] Action created:", Result)
		else
			warn("[ActionEditor] Failed to create Action:", Result)
		end
	end)

	ControllerTrove:Connect(PlayerActionController.UpdateResult :: any, function(Success: boolean, Result: string)
		if Success then
			print("[ActionEditor] Action updated:", Result)
		else
			warn("[ActionEditor] Failed to update Action:", Result)
		end
	end)
end

function ActionEditorController.Stop()
	ControllerTrove:Destroy()
end

function ActionEditorController.Open()
	if IsOpen then
		return
	end

	IsOpen = true
	LockMouse()
	ScreenGui.Enabled = true

	if EditorInstance then
		EditorInstance.SetVisible(true)
	end

	ActionEditorController.EditorOpened:Fire()
end

function ActionEditorController.Close()
	if not IsOpen then
		return
	end

	IsOpen = false
	UnlockMouse()
	ScreenGui.Enabled = false

	if EditorInstance then
		EditorInstance.SetVisible(false)
	end

	ActionEditorController.EditorClosed:Fire()
end

function ActionEditorController.Toggle()
	if IsOpen then
		ActionEditorController.Close()
	else
		ActionEditorController.Open()
	end
end

function ActionEditorController.IsOpen(): boolean
	return IsOpen
end

function ActionEditorController.LoadAction(ActionData: any)
	if EditorInstance then
		EditorInstance.LoadAction(ActionData)
	end
end

function ActionEditorController.LoadActionById(ActionId: string)
	local ActionData = PlayerActionController.GetAction(ActionId)
	if ActionData and EditorInstance then
		EditorInstance.LoadAction(ActionData)
	end
end

function ActionEditorController.NewAction()
	if EditorInstance then
		EditorInstance.NewAction()
	end
end

function ActionEditorController.GetCurrentActionData(): any?
	if EditorInstance then
		return EditorInstance.GetActionData()
	end
	return nil
end

return ActionEditorController