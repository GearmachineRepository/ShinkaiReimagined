--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

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
	Parent: Instance?,
}

function Panel.Create(Config: PanelConfig): Frame
	local PanelFrame = UILibrary.SurfaceContainer({
		Name = Config.Name or "Panel",
		Size = Config.Size or UDim2.fromScale(1, 1),
		Position = Config.Position,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})

	PanelFrame.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface

	if Config.AnchorPoint then
		PanelFrame.AnchorPoint = Config.AnchorPoint
	end

	if Config.Visible ~= nil then
		PanelFrame.Visible = Config.Visible
	end

	local Corner = PanelFrame:FindFirstChildOfClass("UICorner")
	if Corner and Config.CornerRadius then
		Corner.CornerRadius = Config.CornerRadius
	end

	local Stroke = PanelFrame:FindFirstChildOfClass("UIStroke")
	if Stroke then
		if Config.BorderColor then
			Stroke.Color = Config.BorderColor
		else
			Stroke:Destroy()
		end
	end

	if Config.Padding then
		UILibrary.Padding({
			All = Config.Padding,
			Parent = PanelFrame,
		})
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
	ScrollFrame.ZIndex = Theme.ZIndex.Panel

	ScrollFrame.ScrollingDirection = Config.ScrollDirection or Enum.ScrollingDirection.Y
	ScrollFrame.ScrollBarThickness = Config.ScrollBarThickness or 6
	ScrollFrame.ScrollBarImageColor3 = Theme.Colors.BorderLight
	ScrollFrame.CanvasSize = Config.CanvasSize or UDim2.fromScale(0, 0)
	ScrollFrame.AutomaticCanvasSize = Config.AutomaticCanvasSize or Enum.AutomaticSize.Y

	if Config.CornerRadius then
		UILibrary.Corner(ScrollFrame, Config.CornerRadius)
	end

	if Config.BorderColor then
		UILibrary.Stroke(ScrollFrame, Config.BorderColor)
	end

	if Config.Padding then
		UILibrary.Padding({
			All = Config.Padding,
			Parent = ScrollFrame,
		})
	end

	if Config.Parent then
		ScrollFrame.Parent = Config.Parent
	end

	return ScrollFrame
end

return Panel