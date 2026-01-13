--!strict

local Theme = require(script.Parent.Theme)

local UIFactory = {}

export type FrameConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	BorderSizePixel: number?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	ClipsDescendants: boolean?,
	AutomaticSize: Enum.AutomaticSize?,
	Active: boolean?,
	Corner: (UDim | number | boolean)?,
	Stroke: (Color3 | boolean)?,
	StrokeThickness: number?,
	Parent: Instance?,
}

export type TextLabelConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	Text: string?,
	TextColor: Color3?,
	Font: Font?,
	TextSize: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	RichText: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	AutomaticSize: Enum.AutomaticSize?,
	Parent: Instance?,
}

export type TextButtonConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	Text: string?,
	TextColor: Color3?,
	Font: Font?,
	TextSize: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextTruncate: Enum.TextTruncate?,
	AutoButtonColor: boolean?,
	Modal: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	Corner: (UDim | number | boolean)?,
	Stroke: (Color3 | boolean)?,
	StrokeThickness: number?,
	Padding: UDim?,
	Parent: Instance?,
}

export type TextBoxConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	Text: string?,
	PlaceholderText: string?,
	TextColor: Color3?,
	PlaceholderColor: Color3?,
	Font: Font?,
	TextSize: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	MultiLine: boolean?,
	ClearTextOnFocus: boolean?,
	TextEditable: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	Corner: (UDim | number | boolean)?,
	Stroke: (Color3 | boolean)?,
	StrokeThickness: number?,
	Padding: UDim?,
	Parent: Instance?,
}

export type ScrollingFrameConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	BorderSizePixel: number?,
	ScrollBarThickness: number?,
	ScrollBarColor: Color3?,
	CanvasSize: UDim2?,
	AutomaticCanvasSize: Enum.AutomaticSize?,
	ScrollingDirection: Enum.ScrollingDirection?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	Corner: (UDim | number | boolean)?,
	Parent: Instance?,
}

export type ListLayoutConfig = {
	Direction: Enum.FillDirection?,
	Padding: UDim?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	SortOrder: Enum.SortOrder?,
	Parent: Instance?,
}

export type GridLayoutConfig = {
	CellSize: UDim2?,
	CellPadding: UDim2?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
	SortOrder: Enum.SortOrder?,
	FillDirection: Enum.FillDirection?,
	StartCorner: Enum.StartCorner?,
	Parent: Instance?,
}

export type PaddingConfig = {
	Top: UDim?,
	Bottom: UDim?,
	Left: UDim?,
	Right: UDim?,
	All: UDim?,
	Parent: Instance?,
}

export type ImageLabelConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	Image: string?,
	ImageColor: Color3?,
	ImageTransparency: number?,
	ScaleType: Enum.ScaleType?,
	TileSize: UDim2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Visible: boolean?,
	Corner: (UDim | number | boolean)?,
	Parent: Instance?,
}

local function ApplyCorner(Target: GuiObject, CornerValue: UDim | number | boolean): UICorner
	local Corner = Instance.new("UICorner")
	if type(CornerValue) == "number" then
		Corner.CornerRadius = UDim.new(0, CornerValue)
	elseif typeof(CornerValue) == "UDim" then
		Corner.CornerRadius = CornerValue
	elseif CornerValue == true then
		Corner.CornerRadius = Theme.Sizes.BorderRadius
	end
	Corner.Parent = Target
	return Corner
end

local function ApplyStroke(Target: GuiObject, StrokeColor: Color3 | boolean, Thickness: number?): UIStroke
	local Stroke = Instance.new("UIStroke")
	if typeof(StrokeColor) == "Color3" then
		Stroke.Color = StrokeColor
	else
		Stroke.Color = Theme.Colors.Border
	end
	Stroke.Thickness = Thickness or Theme.StrokeSizes.Deslected
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Target
	return Stroke
end

local function ApplyPadding(Target: GuiObject, Config: PaddingConfig): UIPadding
	local Padding = Instance.new("UIPadding")
	if Config.All then
		Padding.PaddingTop = Config.All
		Padding.PaddingBottom = Config.All
		Padding.PaddingLeft = Config.All
		Padding.PaddingRight = Config.All
	else
		if Config.Top then
			Padding.PaddingTop = Config.Top
		end
		if Config.Bottom then
			Padding.PaddingBottom = Config.Bottom
		end
		if Config.Left then
			Padding.PaddingLeft = Config.Left
		end
		if Config.Right then
			Padding.PaddingRight = Config.Right
		end
	end
	Padding.Parent = Target
	return Padding
end

function UIFactory.Frame(Config: FrameConfig): Frame
	local NewFrame = Instance.new("Frame")
	NewFrame.Name = Config.Name or "Frame"
	NewFrame.Size = Config.Size or UDim2.fromScale(1, 1)
	NewFrame.Position = Config.Position or UDim2.fromScale(0, 0)
	NewFrame.AnchorPoint = Config.AnchorPoint or Vector2.zero
	NewFrame.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	NewFrame.BackgroundTransparency = Config.BackgroundTransparency or 0
	NewFrame.BorderSizePixel = Config.BorderSizePixel or 0
	NewFrame.LayoutOrder = Config.LayoutOrder or 0
	NewFrame.ZIndex = Config.ZIndex or 1
	NewFrame.Visible = if Config.Visible ~= nil then Config.Visible else true
	NewFrame.ClipsDescendants = Config.ClipsDescendants or false

	if Config.AutomaticSize then
		NewFrame.AutomaticSize = Config.AutomaticSize
	end

	if Config.Active then
		NewFrame.Active = Config.Active
	end

	if Config.Corner then
		ApplyCorner(NewFrame, Config.Corner)
	end

	if Config.Stroke then
		ApplyStroke(NewFrame, Config.Stroke, Config.StrokeThickness)
	end

	if Config.Parent then
		NewFrame.Parent = Config.Parent
	end

	return NewFrame
end

function UIFactory.TextLabel(Config: TextLabelConfig): TextLabel
	local Label = Instance.new("TextLabel")
	Label.Name = Config.Name or "Label"
	Label.Size = Config.Size or UDim2.fromScale(1, 1)
	Label.Position = Config.Position or UDim2.fromScale(0, 0)
	Label.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Label.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	Label.BackgroundTransparency = if Config.BackgroundTransparency ~= nil then Config.BackgroundTransparency else 1
	Label.Text = Config.Text or ""
	Label.TextColor3 = Config.TextColor or Theme.Colors.Text
	Label.FontFace = Config.Font or Theme.Fonts.Default
	Label.TextSize = Config.TextSize or Theme.TextSizes.Default
	Label.TextXAlignment = Config.TextXAlignment or Enum.TextXAlignment.Left
	Label.TextYAlignment = Config.TextYAlignment or Enum.TextYAlignment.Center
	Label.LayoutOrder = Config.LayoutOrder or 0
	Label.ZIndex = Config.ZIndex or 1
	Label.Visible = if Config.Visible ~= nil then Config.Visible else true

	if Config.TextTruncate then
		Label.TextTruncate = Config.TextTruncate
	end

	if Config.TextWrapped then
		Label.TextWrapped = Config.TextWrapped
	end

	if Config.RichText then
		Label.RichText = Config.RichText
	end

	if Config.AutomaticSize then
		Label.AutomaticSize = Config.AutomaticSize
	end

	if Config.Parent then
		Label.Parent = Config.Parent
	end

	return Label
end

function UIFactory.TextButton(Config: TextButtonConfig): TextButton
	local Button = Instance.new("TextButton")
	Button.Name = Config.Name or "Button"
	Button.Size = Config.Size or UDim2.fromScale(1, 1)
	Button.Position = Config.Position or UDim2.fromScale(0, 0)
	Button.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Button.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	Button.BackgroundTransparency = Config.BackgroundTransparency or 0
	Button.BorderSizePixel = 0
	Button.Text = Config.Text or ""
	Button.TextColor3 = Config.TextColor or Theme.Colors.Text
	Button.FontFace = Config.Font or Theme.Fonts.Default
	Button.TextSize = Config.TextSize or Theme.TextSizes.Default
	Button.AutoButtonColor = if Config.AutoButtonColor ~= nil then Config.AutoButtonColor else false
	Button.LayoutOrder = Config.LayoutOrder or 0
	Button.ZIndex = Config.ZIndex or 1
	Button.Visible = if Config.Visible ~= nil then Config.Visible else true

	if Config.TextXAlignment then
		Button.TextXAlignment = Config.TextXAlignment
	end

	if Config.TextYAlignment then
		Button.TextYAlignment = Config.TextYAlignment
	end

	if Config.TextTruncate then
		Button.TextTruncate = Config.TextTruncate
	end

	if Config.Modal then
		Button.Modal = Config.Modal
	end

	if Config.Corner then
		ApplyCorner(Button, Config.Corner)
	end

	if Config.Stroke then
		ApplyStroke(Button, Config.Stroke, Config.StrokeThickness)
	end

	if Config.Padding then
		ApplyPadding(Button, { All = Config.Padding })
	end

	if Config.Parent then
		Button.Parent = Config.Parent
	end

	return Button
end

function UIFactory.TextBox(Config: TextBoxConfig): TextBox
	local Box = Instance.new("TextBox")
	Box.Name = Config.Name or "TextBox"
	Box.Size = Config.Size or UDim2.fromScale(1, 1)
	Box.Position = Config.Position or UDim2.fromScale(0, 0)
	Box.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Box.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.BackgroundDark
	Box.BackgroundTransparency = Config.BackgroundTransparency or 0
	Box.BorderSizePixel = 0
	Box.Text = Config.Text or ""
	Box.PlaceholderText = Config.PlaceholderText or ""
	Box.TextColor3 = Config.TextColor or Theme.Colors.Text
	Box.PlaceholderColor3 = Config.PlaceholderColor or Theme.Colors.TextMuted
	Box.FontFace = Config.Font or Theme.Fonts.Default
	Box.TextSize = Config.TextSize or Theme.TextSizes.Default
	Box.TextXAlignment = Config.TextXAlignment or Enum.TextXAlignment.Left
	Box.ClearTextOnFocus = if Config.ClearTextOnFocus ~= nil then Config.ClearTextOnFocus else false
	Box.LayoutOrder = Config.LayoutOrder or 0
	Box.ZIndex = Config.ZIndex or 1
	Box.Visible = if Config.Visible ~= nil then Config.Visible else true

	if Config.TextYAlignment then
		Box.TextYAlignment = Config.TextYAlignment
	end

	if Config.TextTruncate then
		Box.TextTruncate = Config.TextTruncate
	end

	if Config.TextWrapped then
		Box.TextWrapped = Config.TextWrapped
	end

	if Config.MultiLine then
		Box.MultiLine = Config.MultiLine
	end

	if Config.TextEditable ~= nil then
		Box.TextEditable = Config.TextEditable
	end

	if Config.Corner then
		ApplyCorner(Box, Config.Corner)
	end

	if Config.Stroke then
		ApplyStroke(Box, Config.Stroke, Config.StrokeThickness)
	end

	if Config.Padding then
		ApplyPadding(Box, { All = Config.Padding })
	end

	if Config.Parent then
		Box.Parent = Config.Parent
	end

	return Box
end

function UIFactory.ScrollingFrame(Config: ScrollingFrameConfig): ScrollingFrame
	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Name = Config.Name or "ScrollingFrame"
	Scroll.Size = Config.Size or UDim2.fromScale(1, 1)
	Scroll.Position = Config.Position or UDim2.fromScale(0, 0)
	Scroll.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Scroll.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	Scroll.BackgroundTransparency = if Config.BackgroundTransparency ~= nil then Config.BackgroundTransparency else 1
	Scroll.BorderSizePixel = Config.BorderSizePixel or 0
	Scroll.ScrollBarThickness = Config.ScrollBarThickness or 4
	Scroll.ScrollBarImageColor3 = Config.ScrollBarColor or Theme.Colors.TextMuted
	Scroll.CanvasSize = Config.CanvasSize or UDim2.fromScale(0, 0)
	Scroll.LayoutOrder = Config.LayoutOrder or 0
	Scroll.ZIndex = Config.ZIndex or 1
	Scroll.Visible = if Config.Visible ~= nil then Config.Visible else true

	if Config.AutomaticCanvasSize then
		Scroll.AutomaticCanvasSize = Config.AutomaticCanvasSize
	end

	if Config.ScrollingDirection then
		Scroll.ScrollingDirection = Config.ScrollingDirection
	end

	if Config.Corner then
		ApplyCorner(Scroll, Config.Corner)
	end

	if Config.Parent then
		Scroll.Parent = Config.Parent
	end

	return Scroll
end

function UIFactory.ListLayout(Config: ListLayoutConfig): UIListLayout
	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Config.Direction or Enum.FillDirection.Vertical
	Layout.Padding = Config.Padding or UDim.new(0, 0)
	Layout.SortOrder = Config.SortOrder or Enum.SortOrder.LayoutOrder

	if Config.HorizontalAlignment then
		Layout.HorizontalAlignment = Config.HorizontalAlignment
	end

	if Config.VerticalAlignment then
		Layout.VerticalAlignment = Config.VerticalAlignment
	end

	if Config.Parent then
		Layout.Parent = Config.Parent
	end

	return Layout
end

function UIFactory.GridLayout(Config: GridLayoutConfig): UIGridLayout
	local Layout = Instance.new("UIGridLayout")
	Layout.CellSize = Config.CellSize or UDim2.fromOffset(100, 100)
	Layout.CellPadding = Config.CellPadding or UDim2.fromOffset(0, 0)
	Layout.SortOrder = Config.SortOrder or Enum.SortOrder.LayoutOrder

	if Config.HorizontalAlignment then
		Layout.HorizontalAlignment = Config.HorizontalAlignment
	end

	if Config.VerticalAlignment then
		Layout.VerticalAlignment = Config.VerticalAlignment
	end

	if Config.FillDirection then
		Layout.FillDirection = Config.FillDirection
	end

	if Config.StartCorner then
		Layout.StartCorner = Config.StartCorner
	end

	if Config.Parent then
		Layout.Parent = Config.Parent
	end

	return Layout
end

function UIFactory.Padding(Config: PaddingConfig): UIPadding
	return ApplyPadding(Config.Parent :: GuiObject, Config)
end

function UIFactory.Corner(Parent: Instance, Radius: UDim | number | boolean): UICorner
	return ApplyCorner(Parent :: GuiObject, Radius)
end

function UIFactory.Stroke(Parent: Instance, StrokeColor: Color3?, Thickness: number?): UIStroke
	return ApplyStroke(Parent :: GuiObject, StrokeColor or true, Thickness)
end

function UIFactory.Scale(Parent: Instance, ScaleValue: number): UIScale
	local Scale = Instance.new("UIScale")
	Scale.Scale = ScaleValue
	Scale.Parent = Parent
	return Scale
end

function UIFactory.ImageLabel(Config: ImageLabelConfig): ImageLabel
	local Image = Instance.new("ImageLabel")
	Image.Name = Config.Name or "Image"
	Image.Size = Config.Size or UDim2.fromScale(1, 1)
	Image.Position = Config.Position or UDim2.fromScale(0, 0)
	Image.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Image.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.Surface
	Image.BackgroundTransparency = if Config.BackgroundTransparency ~= nil then Config.BackgroundTransparency else 1
	Image.BorderSizePixel = 0
	Image.Image = Config.Image or ""
	Image.ImageColor3 = Config.ImageColor or Color3.new(1, 1, 1)
	Image.ImageTransparency = Config.ImageTransparency or 0
	Image.LayoutOrder = Config.LayoutOrder or 0
	Image.ZIndex = Config.ZIndex or 1
	Image.Visible = if Config.Visible ~= nil then Config.Visible else true

	if Config.ScaleType then
		Image.ScaleType = Config.ScaleType
	end

	if Config.TileSize then
		Image.TileSize = Config.TileSize
	end

	if Config.Corner then
		ApplyCorner(Image, Config.Corner)
	end

	if Config.Parent then
		Image.Parent = Config.Parent
	end

	return Image
end

function UIFactory.Overlay(Config: { ZIndex: number?, Parent: Instance? }): TextButton
	return UIFactory.TextButton({
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor = Theme.Colors.Overlay,
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = Config.ZIndex or Theme.ZIndex.Modal,
		Parent = Config.Parent,
	})
end

function UIFactory.ClickBlocker(Config: { Name: string?, ZIndex: number?, Parent: Instance? }): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "ClickBlocker",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = Config.ZIndex or 1,
		Parent = Config.Parent,
	})
end

return UIFactory