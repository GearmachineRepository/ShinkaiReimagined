--!strict

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)

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

	local Container = Instance.new("Frame")
	Container.Name = "Tooltip"
	Container.BackgroundColor3 = Theme.Colors.Surface
	Container.BorderSizePixel = 0
	Container.AutomaticSize = Enum.AutomaticSize.XY
	Container.ZIndex = Theme.ZIndex.Tooltip
	Container.Parent = ScreenGui

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusSmall)
	Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 6)
	Padding.PaddingBottom = UDim.new(0, 6)
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Container

	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	SizeConstraint.Parent = Container

	local Label = Instance.new("TextLabel")
	Label.Name = "Text"
	Label.Size = UDim2.fromScale(0, 0)
	Label.AutomaticSize = Enum.AutomaticSize.XY
	Label.BackgroundTransparency = 1
	Label.Text = Text
	Label.TextColor3 = Theme.Colors.Text
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.TextWrapped = true
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.ZIndex = Theme.ZIndex.Tooltip + 1
	Label.Parent = Container

	local ScreenSize = ScreenGui.AbsoluteSize
	local PositionX = MousePosition.X + PADDING
	local PositionY = MousePosition.Y + PADDING

	task.defer(function()
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
		local Status = coroutine.status(ShowThread)
		if Status == "suspended" then
			task.cancel(ShowThread)
		end
		ShowThread = nil
	end

	if CurrentTooltip then
		CurrentTooltip:Destroy()
		CurrentTooltip = nil
	end
end

function Tooltip.ShowDelayed(Text: string, Parent: GuiObject)
	Tooltip.Hide()

	ShowThread = task.delay(SHOW_DELAY, function()
		Tooltip.Show(Text, Parent)
		ShowThread = nil
	end)
end

function Tooltip.Bind(Element: GuiObject, Text: string)
	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, Element.MouseEnter:Connect(function()
		Tooltip.ShowDelayed(Text, Element)
	end))

	table.insert(Connections, Element.MouseLeave:Connect(function()
		Tooltip.Hide()
	end))

	table.insert(Connections, Element.Destroying:Connect(function()
		Tooltip.Hide()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
	end))

	return function()
		Tooltip.Hide()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
	end
end

return Tooltip