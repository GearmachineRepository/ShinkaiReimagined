--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local Packets = require(Shared.Network.Packets)

local PlayerActionService = require(Server.Services.PlayerActionService)

local TEST_TOOL_NAME = "ActionTester"

local EquipCube = workspace:WaitForChild("EquipCube", 5)
local UnequipCube = workspace:WaitForChild("UnequipCube", 5)

local EquipDetector: ClickDetector? = nil
local UnequipDetector: ClickDetector? = nil

local function GetOrCreateClickDetector(Parent: BasePart): ClickDetector
	local Existing = Parent:FindFirstChildOfClass("ClickDetector")
	if Existing then
		return Existing
	end

	local Detector = Instance.new("ClickDetector")
	Detector.MaxActivationDistance = 16
	Detector.Parent = Parent
	return Detector
end

local function GetTestTool(Player: Player): Tool?
	local Backpack = Player:FindFirstChild("Backpack")
	local Character = Player.Character

	if Backpack then
		local Tool = Backpack:FindFirstChild(TEST_TOOL_NAME)
		if Tool and Tool:IsA("Tool") then
			return Tool
		end
	end

	if Character then
		local Tool = Character:FindFirstChild(TEST_TOOL_NAME)
		if Tool and Tool:IsA("Tool") then
			return Tool
		end
	end

	return nil
end

local function RemoveTestTool(Player: Player)
	local Tool = GetTestTool(Player)
	if Tool then
		local ActionId = Tool:GetAttribute("ActionId") :: string?
		if ActionId and PlayerActionService.IsPlayerAction(ActionId) then
			PlayerActionService.UnregisterFromExecution(ActionId)
		end
		Tool:Destroy()
	end
end

local function CreateTestTool(Player: Player, ActionId: string, DisplayName: string): Tool?
	RemoveTestTool(Player)

	local Backpack = Player:FindFirstChild("Backpack")
	if not Backpack then
		return nil
	end

	if not PlayerActionService.RegisterForExecution(Player, ActionId) then
		warn("[ActionEquipCubes] Failed to register action:", ActionId)
		return nil
	end

	local Tool = Instance.new("Tool")
	Tool.Name = TEST_TOOL_NAME
	Tool.RequiresHandle = false
	Tool.ToolTip = DisplayName
	Tool:SetAttribute("ActionId", ActionId)
	Tool:SetAttribute("IsTestTool", true)
	Tool.Parent = Backpack

	return Tool
end

local function OnEquipClicked(Player: Player)
	Packets.PlayerActionEquipPrompt:FireClient(Player)
end

local function OnUnequipClicked(Player: Player)
	RemoveTestTool(Player)
	Packets.PlayerActionUnequipPrompt:FireClient(Player)
end

local function OnEquipRequest(Player: Player, ActionId: string)
	local Action = PlayerActionService.GetAction(Player, ActionId)
	if not Action then
		Packets.PlayerActionEquipToolResult:FireClient(Player, false, "ActionNotFound")
		return
	end

	local Tool = CreateTestTool(Player, ActionId, Action.DisplayName or ActionId)
	if Tool then
		Packets.PlayerActionEquipToolResult:FireClient(Player, true, ActionId)
	else
		Packets.PlayerActionEquipToolResult:FireClient(Player, false, "FailedToCreate")
	end
end

local function Setup()
	if not EquipCube or not UnequipCube then
		warn("[ActionEquipCubes] Missing EquipCube or UnequipCube in workspace")
		return
	end

	if not EquipCube:IsA("BasePart") or not UnequipCube:IsA("BasePart") then
		warn("[ActionEquipCubes] EquipCube and UnequipCube must be BaseParts")
		return
	end

	EquipDetector = GetOrCreateClickDetector(EquipCube :: BasePart) :: ClickDetector?
	UnequipDetector = GetOrCreateClickDetector(UnequipCube :: BasePart) :: ClickDetector?

    if not EquipDetector or not UnequipDetector then return end

	EquipDetector.MouseClick:Connect(OnEquipClicked)
	UnequipDetector.MouseClick:Connect(OnUnequipClicked)

	Packets.PlayerActionEquipTool.OnServerEvent:Connect(OnEquipRequest)

	Players.PlayerRemoving:Connect(function(Player: Player)
		RemoveTestTool(Player)
	end)

	print("[ActionEquipCubes] Ready")
end

Setup()