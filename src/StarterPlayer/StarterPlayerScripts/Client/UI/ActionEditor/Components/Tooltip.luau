--!strict

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

local Tooltip = {}

local SHOW_DELAY = 0.4
local PADDING = 8
local MAX_WIDTH = 250

local CurrentTooltip: Frame? = nil
local ShowThread: thread? = nil

function Tooltip.Show(Text: string, Parent: GuiObject)
	Tooltip.Hide()

	local ScreenGui = Parent:FindFirstAncestorOfClass("ScreenGui")
	if not ScreenGui then
		return
	end

	local MousePosition = UserInputService:GetMouseLocation()
	local GuiInset = GuiService:GetGuiInset()
	MousePosition = MousePosition - GuiInset

	local Container = UILibrary.SurfaceContainer({
		Name = "Tooltip",
		Size = UDim2.fromOffset(0, 0),
		ZIndex = Theme.ZIndex.Tooltip,
		Parent = ScreenGui,
	})

	Container.AutomaticSize = Enum.AutomaticSize.XY

	UILibrary.Padding({
		Top = UDim.new(0, 6),
		Bottom = UDim.new(0, 6),
		Left = UDim.new(0, 8),
		Right = UDim.new(0, 8),
		Parent = Container,
	})

	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	SizeConstraint.Parent = Container

	local Label = UILibrary.BodyLabel({
		Name = "Text",
		Text = Text,
		Size = UDim2.fromScale(0, 0),
		ZIndex = Theme.ZIndex.Tooltip + 1,
		Parent = Container,
	})

	Label.AutomaticSize = Enum.AutomaticSize.XY
	Label.TextSize = Theme.TextSizes.Small

	local ScreenSize = ScreenGui.AbsoluteSize
	local PositionX = MousePosition.X + PADDING
	local PositionY = MousePosition.Y + PADDING

	task.defer(function()
		if not Container or not Container.Parent then
			return
		end

		local TooltipSize = Container.AbsoluteSize

		if PositionX + TooltipSize.X > ScreenSize.X - PADDING then
			PositionX = MousePosition.X - TooltipSize.X - PADDING
		end

		if PositionY + TooltipSize.Y > ScreenSize.Y - PADDING then
			PositionY = MousePosition.Y - TooltipSize.Y - PADDING
		end

		Container.Position = UDim2.fromOffset(PositionX, PositionY)
	end)

	Container.Position = UDim2.fromOffset(PositionX, PositionY)
	CurrentTooltip = Container
end

function Tooltip.Hide()
	if ShowThread then
		pcall(task.cancel, ShowThread)
		ShowThread = nil
	end

	if CurrentTooltip then
		CurrentTooltip:Destroy()
		CurrentTooltip = nil
	end
end

function Tooltip.Bind(Target: GuiObject, Text: string): () -> ()
	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, Target.MouseEnter:Connect(function()
		if Text == "" then
			return
		end

		ShowThread = task.delay(SHOW_DELAY, function()
			Tooltip.Show(Text, Target)
		end)
	end))

	table.insert(Connections, Target.MouseLeave:Connect(function()
		Tooltip.Hide()
	end))

	if Target:IsA("GuiButton") then
		table.insert(Connections, Target.MouseButton1Click:Connect(function()
			Tooltip.Hide()
		end))
	end

	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end
end

return Tooltip