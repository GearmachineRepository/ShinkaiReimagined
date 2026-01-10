--!strict

local Theme = require(script.Parent.Parent.Theme)

local Panel = {}

export type PanelConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BorderColor: Color3?,
	CornerRadius: UDim?,
	Padding: UDim?,
	LayoutOrder: number?,
	Visible: boolean?,
	Parent: GuiObject?,
}

function Panel.Create(Config: PanelConfig): Frame
	local PanelFrame = Instance.new("Frame")
	PanelFrame.Name = Config.Name or "Panel"
	PanelFrame.Size = Config.Size or UDim2.fromScale(1, 1)
	PanelFrame.Position = Config.Position or UDim2.fromScale(0, 0)
	PanelFrame.AnchorPoint = Config.AnchorPoint or Vector2.zero
	PanelFrame.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	PanelFrame.BorderSizePixel = 0
	PanelFrame.LayoutOrder = Config.LayoutOrder or 0
	PanelFrame.Visible = if Config.Visible ~= nil then Config.Visible else true

	Theme.ApplyCorner(PanelFrame, Config.CornerRadius)

	if Config.BorderColor then
		Theme.ApplyStroke(PanelFrame, Config.BorderColor)
	end

	if Config.Padding then
		Theme.ApplyPadding(PanelFrame, Config.Padding)
	end

	if Config.Parent then
		PanelFrame.Parent = Config.Parent
	end

	return PanelFrame
end

export type ScrollPanelConfig = PanelConfig & {
	ScrollDirection: Enum.ScrollingDirection?,
	ScrollBarThickness: number?,
	CanvasSize: UDim2?,
	AutomaticCanvasSize: Enum.AutomaticSize?,
}

function Panel.CreateScrollable(Config: ScrollPanelConfig): ScrollingFrame
	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Name = Config.Name or "ScrollPanel"
	ScrollFrame.Size = Config.Size or UDim2.fromScale(1, 1)
	ScrollFrame.Position = Config.Position or UDim2.fromScale(0, 0)
	ScrollFrame.AnchorPoint = Config.AnchorPoint or Vector2.zero
	ScrollFrame.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.LayoutOrder = Config.LayoutOrder or 0
	ScrollFrame.Visible = if Config.Visible ~= nil then Config.Visible else true

	ScrollFrame.ScrollingDirection = Config.ScrollDirection or Enum.ScrollingDirection.Y
	ScrollFrame.ScrollBarThickness = Config.ScrollBarThickness or 6
	ScrollFrame.ScrollBarImageColor3 = Theme.Colors.BorderLight
	ScrollFrame.CanvasSize = Config.CanvasSize or UDim2.fromScale(0, 0)
	ScrollFrame.AutomaticCanvasSize = Config.AutomaticCanvasSize or Enum.AutomaticSize.Y

	Theme.ApplyCorner(ScrollFrame, Config.CornerRadius)

	if Config.BorderColor then
		Theme.ApplyStroke(ScrollFrame, Config.BorderColor)
	end

	if Config.Padding then
		Theme.ApplyPadding(ScrollFrame, Config.Padding)
	end

	if Config.Parent then
		ScrollFrame.Parent = Config.Parent
	end

	return ScrollFrame
end

return Panel