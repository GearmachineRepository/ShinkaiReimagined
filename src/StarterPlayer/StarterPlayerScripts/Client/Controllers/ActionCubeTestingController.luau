--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)
local Combat = require(Shared.Combat)

local Trove = Packages.Trove

local ActionRegistry = Combat.ActionRegistry
local ActionExecutor = Combat.Runtime.ActionExecutor

local BACKGROUND_COLOR = Color3.fromRGB(30, 30, 35)
local SURFACE_COLOR = Color3.fromRGB(45, 45, 50)
local BORDER_COLOR = Color3.fromRGB(60, 60, 65)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local PRIMARY_COLOR = Color3.fromRGB(88, 101, 242)
local ERROR_COLOR = Color3.fromRGB(237, 66, 69)
local SUCCESS_COLOR = Color3.fromRGB(87, 242, 135)

local PlayerActionEquipController = {}

PlayerActionEquipController.Dependencies = { "PlayerActionController" }

local ControllerTrove: typeof(Trove.new()) = nil :: any
local ScreenGui: ScreenGui? = nil
local UiTrove: typeof(Trove.new())? = nil

local function GetLocalPlayerGui(): PlayerGui
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	return PlayerGui
end

local function CreateScreenGui(): ScreenGui
	local PlayerGui = GetLocalPlayerGui()

	local Existing = PlayerGui:FindFirstChild("ActionEquipGui")
	if Existing then
		Existing:Destroy()
	end

	local Gui = Instance.new("ScreenGui")
	Gui.Name = "ActionEquipGui"
	Gui.ResetOnSpawn = false
	Gui.DisplayOrder = 150
	Gui.Parent = PlayerGui

	return Gui
end

local function CreateFrame(FrameName: string, FrameSize: UDim2, FramePosition: UDim2, Parent: GuiObject): Frame
	local NewFrame = Instance.new("Frame")
	NewFrame.Name = FrameName
	NewFrame.Size = FrameSize
	NewFrame.Position = FramePosition
	NewFrame.BackgroundColor3 = BACKGROUND_COLOR
	NewFrame.BorderSizePixel = 0
	NewFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = NewFrame

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = BORDER_COLOR
	Stroke.Thickness = 1
	Stroke.Parent = NewFrame

	return NewFrame
end

local function CreateButton(ButtonText: string, ButtonSize: UDim2, ButtonColor: Color3, Parent: GuiObject): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = ButtonSize
	Button.BackgroundColor3 = ButtonColor
	Button.BorderSizePixel = 0
	Button.Text = ButtonText
	Button.TextColor3 = TEXT_COLOR
	Button.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	Button.TextSize = 14
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Button

	return Button
end

local function CreateLabel(LabelText: string, LabelSize: UDim2, Parent: GuiObject): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Size = LabelSize
	Label.BackgroundTransparency = 1
	Label.Text = LabelText
	Label.TextColor3 = TEXT_COLOR
	Label.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	Label.TextSize = 18
	Label.Parent = Parent
	return Label
end

local function DestroyUiTrove()
	if UiTrove then
		UiTrove:Destroy()
		UiTrove = nil
	end
end

local function ClearScreenGui()
	if not ScreenGui then
		return
	end

	for _, Child in ScreenGui:GetChildren() do
		Child:Destroy()
	end
end

local function CloseUi()
	DestroyUiTrove()
	ClearScreenGui()
end

local function GetPlayerActionController()
	local LocalPlayer = Players.LocalPlayer
	local ClientFolder = LocalPlayer.PlayerScripts:WaitForChild("Client")
	return require(ClientFolder.Controllers.PlayerActionController)
end

local function ShowEquipUi()
	if not ScreenGui then
		return
	end

	CloseUi()

	local NewUiTrove = Trove.new()
	UiTrove = NewUiTrove

	local PlayerActionController = GetPlayerActionController()

	local Container = CreateFrame("Container", UDim2.fromOffset(350, 400), UDim2.fromScale(0.5, 0.5), ScreenGui :: any)
	Container.AnchorPoint = Vector2.new(0.5, 0.5)

	local Title = CreateLabel("Equip Action", UDim2.new(1, 0, 0, 40), Container)
	Title.Position = UDim2.fromOffset(0, 10)
	Title.TextXAlignment = Enum.TextXAlignment.Center

	local CloseButton = CreateButton("X", UDim2.fromOffset(30, 30), ERROR_COLOR, Container)
	CloseButton.Position = UDim2.new(1, -40, 0, 10)
	NewUiTrove:Connect(CloseButton.MouseButton1Click, CloseUi)

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Name = "ActionList"
	ScrollFrame.Size = UDim2.new(1, -20, 1, -110)
	ScrollFrame.Position = UDim2.fromOffset(10, 55)
	ScrollFrame.BackgroundColor3 = SURFACE_COLOR
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 6
	ScrollFrame.ScrollBarImageColor3 = BORDER_COLOR
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollFrame.Parent = Container

	local ScrollCorner = Instance.new("UICorner")
	ScrollCorner.CornerRadius = UDim.new(0, 6)
	ScrollCorner.Parent = ScrollFrame

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 5)
	ListLayout.Parent = ScrollFrame

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingTop = UDim.new(0, 5)
	ListPadding.PaddingBottom = UDim.new(0, 5)
	ListPadding.PaddingLeft = UDim.new(0, 5)
	ListPadding.PaddingRight = UDim.new(0, 5)
	ListPadding.Parent = ScrollFrame

	local Actions = PlayerActionController.GetAllActions()
	local ActionCount = 0

	for ActionId, ActionData in Actions do
		ActionCount = ActionCount + 1

		local ItemFrame = Instance.new("Frame")
		ItemFrame.Name = ActionId
		ItemFrame.Size = UDim2.new(1, -10, 0, 50)
		ItemFrame.BackgroundColor3 = BACKGROUND_COLOR
		ItemFrame.BorderSizePixel = 0
		ItemFrame.Parent = ScrollFrame

		local ItemCorner = Instance.new("UICorner")
		ItemCorner.CornerRadius = UDim.new(0, 6)
		ItemCorner.Parent = ItemFrame

		local NameLabel = Instance.new("TextLabel")
		NameLabel.Size = UDim2.new(1, -80, 1, 0)
		NameLabel.Position = UDim2.fromOffset(10, 0)
		NameLabel.BackgroundTransparency = 1
		NameLabel.Text = ActionData.DisplayName or ActionId
		NameLabel.TextColor3 = TEXT_COLOR
		NameLabel.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		NameLabel.TextSize = 14
		NameLabel.TextXAlignment = Enum.TextXAlignment.Left
		NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		NameLabel.Parent = ItemFrame

		local EquipButton = CreateButton("Equip", UDim2.fromOffset(60, 35), PRIMARY_COLOR, ItemFrame)
		EquipButton.Position = UDim2.new(1, -70, 0.5, -17)

		NewUiTrove:Connect(EquipButton.MouseButton1Click, function()
			EquipButton.Text = "..."
			EquipButton.BackgroundColor3 = SURFACE_COLOR
			Packets.PlayerActionEquipTool:Fire(ActionId)
		end)
	end

	if ActionCount == 0 then
		local EmptyLabel = Instance.new("TextLabel")
		EmptyLabel.Size = UDim2.new(1, 0, 0, 50)
		EmptyLabel.BackgroundTransparency = 1
		EmptyLabel.Text = "No Actions created yet.\nUse the Action Editor (T) to create Actions."
		EmptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		EmptyLabel.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
		EmptyLabel.TextSize = 13
		EmptyLabel.Parent = ScrollFrame
	end

	local CancelButton = CreateButton("Cancel", UDim2.new(1, -20, 0, 40), SURFACE_COLOR, Container)
	CancelButton.Position = UDim2.new(0, 10, 1, -50)
	NewUiTrove:Connect(CancelButton.MouseButton1Click, CloseUi)
end

local function ShowUnequipUi()
	if not ScreenGui then
		return
	end

	CloseUi()

	local NewUiTrove = Trove.new()
	UiTrove = NewUiTrove

	local Container = CreateFrame("Container", UDim2.fromOffset(300, 120), UDim2.fromScale(0.5, 0.5), ScreenGui :: any)
	Container.AnchorPoint = Vector2.new(0.5, 0.5)

	local Title = CreateLabel("Action Unequipped", UDim2.new(1, 0, 0, 40), Container)
	Title.Position = UDim2.fromOffset(0, 15)
	Title.TextXAlignment = Enum.TextXAlignment.Center
	Title.TextSize = 16

	local OkButton = CreateButton("OK", UDim2.new(1, -20, 0, 35), PRIMARY_COLOR, Container)
	OkButton.Position = UDim2.new(0, 10, 1, -45)
	NewUiTrove:Connect(OkButton.MouseButton1Click, CloseUi)

	task.delay(2, function()
		if UiTrove == NewUiTrove then
			CloseUi()
		end
	end)
end

local function ShowResultUi(IsSuccess: boolean, MessageText: string)
	if not ScreenGui then
		return
	end

	CloseUi()

	if IsSuccess then
		local ActionId = MessageText
		local PlayerActionController = GetPlayerActionController()
		local ActionData = PlayerActionController.GetAction(ActionId)

		if ActionData then
			if ActionRegistry.Has(ActionId) then
				ActionRegistry.Unregister(ActionId)
			end
			ActionRegistry.Register(ActionData)
			ActionExecutor.ClearCache(ActionId)
		end
	end

	local NewUiTrove = Trove.new()
	UiTrove = NewUiTrove

	local Container = CreateFrame("Container", UDim2.fromOffset(300, 120), UDim2.fromScale(0.5, 0.5), ScreenGui :: any)
	Container.AnchorPoint = Vector2.new(0.5, 0.5)

	local TitleText = if IsSuccess then "Action Equipped!" else "Failed"
	local Title = CreateLabel(TitleText, UDim2.new(1, 0, 0, 40), Container)
	Title.Position = UDim2.fromOffset(0, 15)
	Title.TextXAlignment = Enum.TextXAlignment.Center
	Title.TextSize = 16
	Title.TextColor3 = if IsSuccess then SUCCESS_COLOR else ERROR_COLOR

	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Size = UDim2.new(1, -20, 0, 20)
	MessageLabel.Position = UDim2.fromOffset(10, 45)
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Text = if IsSuccess then "Tool added to backpack" else MessageText
	MessageLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	MessageLabel.FontFace = Font.fromEnum(Enum.Font.GothamMedium)
	MessageLabel.TextSize = 12
	MessageLabel.Parent = Container

	local OkButton = CreateButton("OK", UDim2.new(1, -20, 0, 35), PRIMARY_COLOR, Container)
	OkButton.Position = UDim2.new(0, 10, 1, -45)
	NewUiTrove:Connect(OkButton.MouseButton1Click, CloseUi)

	if IsSuccess then
		task.delay(1.5, function()
			if UiTrove == NewUiTrove then
				CloseUi()
			end
		end)
	end
end

function PlayerActionEquipController.Init()
	ControllerTrove = Trove.new()
	ScreenGui = CreateScreenGui()
end

function PlayerActionEquipController.Start()
	if not ControllerTrove then
		ControllerTrove = Trove.new()
	end

	ControllerTrove:Connect(Packets.PlayerActionEquipPrompt.OnClientEvent :: any, ShowEquipUi)
	ControllerTrove:Connect(Packets.PlayerActionUnequipPrompt.OnClientEvent :: any, ShowUnequipUi)
	ControllerTrove:Connect(Packets.PlayerActionEquipToolResult.OnClientEvent :: any, ShowResultUi)
end

function PlayerActionEquipController.Stop()
	CloseUi()

	if ScreenGui then
		ScreenGui:Destroy()
		ScreenGui = nil
	end

	if ControllerTrove then
		ControllerTrove:Destroy()
	end
end

return PlayerActionEquipController