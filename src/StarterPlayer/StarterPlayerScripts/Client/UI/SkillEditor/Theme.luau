--!strict

local Theme = {}

Theme.Colors = {
	Background = Color3.fromRGB(30, 30, 35),
	BackgroundDark = Color3.fromRGB(22, 22, 26),
	BackgroundLight = Color3.fromRGB(45, 45, 52),

	Surface = Color3.fromRGB(40, 40, 48),
	SurfaceHover = Color3.fromRGB(50, 50, 60),
	SurfaceActive = Color3.fromRGB(60, 60, 72),

	Border = Color3.fromRGB(60, 60, 70),
	BorderLight = Color3.fromRGB(80, 80, 95),
	BorderFocus = Color3.fromRGB(100, 140, 200),

	Text = Color3.fromRGB(220, 220, 225),
	TextMuted = Color3.fromRGB(140, 140, 150),
	TextDisabled = Color3.fromRGB(90, 90, 100),

	Primary = Color3.fromRGB(80, 130, 200),
	PrimaryHover = Color3.fromRGB(100, 150, 220),
	PrimaryActive = Color3.fromRGB(60, 110, 180),

	Success = Color3.fromRGB(80, 180, 120),
	Warning = Color3.fromRGB(220, 180, 80),
	Error = Color3.fromRGB(200, 80, 80),

	NodeWait = Color3.fromRGB(120, 120, 140),
	NodeAnimation = Color3.fromRGB(180, 120, 200),
	NodeSound = Color3.fromRGB(200, 160, 80),
	NodeVelocity = Color3.fromRGB(80, 160, 200),
	NodeHitbox = Color3.fromRGB(200, 80, 80),
	NodeHitCancel = Color3.fromRGB(200, 120, 80),
	NodeSkill = Color3.fromRGB(160, 80, 200),
	NodeBranch = Color3.fromRGB(80, 200, 160),
	NodeSignal = Color3.fromRGB(200, 200, 80),
	NodeGate = Color3.fromRGB(80, 200, 200),
	NodeHealth = Color3.fromRGB(80, 200, 80),

	PortFlow = Color3.fromRGB(200, 200, 200),
	PortSignal = Color3.fromRGB(200, 200, 80),

	WireFlow = Color3.fromRGB(180, 180, 180),
	WireSignal = Color3.fromRGB(200, 200, 80),
	WirePreview = Color3.fromRGB(100, 140, 200),

	BranchHeader = Color3.fromRGB(50, 50, 60),
	BranchHeaderEntry = Color3.fromRGB(60, 80, 60),
}

Theme.Sizes = {
	BorderRadius = UDim.new(0, 6),
	BorderRadiusSmall = UDim.new(0, 4),
	BorderRadiusLarge = UDim.new(0, 8),

	Padding = UDim.new(0, 8),
	PaddingSmall = UDim.new(0, 4),
	PaddingLarge = UDim.new(0, 12),

	Gap = UDim.new(0, 6),
	GapSmall = UDim.new(0, 4),
	GapLarge = UDim.new(0, 10),

	ButtonHeight = 32,
	InputHeight = 28,

	NodeWidth = 160,
	NodeHeaderHeight = 28,
	NodePortHeight = 22,
	NodePortRadius = 6,

	WireThickness = 2,
	WireThicknessHover = 3,

	BranchHeaderHeight = 32,
	BranchMinWidth = 200,
	BranchPadding = 16,

	PanelWidth = 240,
	ToolbarHeight = 40,
}

Theme.Fonts = {
	Default = Font.fromEnum(Enum.Font.GothamMedium),
	Bold = Font.fromEnum(Enum.Font.GothamBold),
	Mono = Font.fromEnum(Enum.Font.RobotoMono),
}

Theme.TextSizes = {
	Small = 12,
	Default = 14,
	Large = 16,
	Header = 18,
}

Theme.ZIndex = {
	Background = 1,
	BranchContainer = 10,
	Node = 20,
	NodeSelected = 25,
	Wire = 15,
	WirePreview = 30,
	Port = 22,
	Tooltip = 100,
	Dropdown = 90,
	Modal = 200,
}

function Theme.ApplyCorner(Target: GuiObject, Radius: UDim?): UICorner
	local ExistingCorner: Instance? = Target:FindFirstChildOfClass("UICorner")
	local Corner: UICorner

	if ExistingCorner and ExistingCorner:IsA("UICorner") then
		Corner = ExistingCorner
	else
		Corner = Instance.new("UICorner")
		Corner.Parent = Target
	end

	Corner.CornerRadius = Radius or Theme.Sizes.BorderRadius
	return Corner
end

function Theme.ApplyStroke(Target: GuiObject, StrokeColor: Color3?, Thickness: number?): UIStroke
	local ExistingStroke: Instance? = Target:FindFirstChildOfClass("UIStroke")
	local Stroke: UIStroke

	if ExistingStroke and ExistingStroke:IsA("UIStroke") then
		Stroke = ExistingStroke
	else
		Stroke = Instance.new("UIStroke")
		Stroke.Parent = Target
	end

	Stroke.Color = StrokeColor or Theme.Colors.Border
	Stroke.Thickness = Thickness or 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return Stroke
end

function Theme.ApplyPadding(Target: GuiObject, PaddingValue: UDim?): UIPadding
	local ExistingPadding: Instance? = Target:FindFirstChildOfClass("UIPadding")
	local Padding: UIPadding

	if ExistingPadding and ExistingPadding:IsA("UIPadding") then
		Padding = ExistingPadding
	else
		Padding = Instance.new("UIPadding")
		Padding.Parent = Target
	end

	local Value: UDim = PaddingValue or Theme.Sizes.Padding
	Padding.PaddingTop = Value
	Padding.PaddingBottom = Value
	Padding.PaddingLeft = Value
	Padding.PaddingRight = Value
	return Padding
end

function Theme.ApplyListLayout(Target: GuiObject, Direction: Enum.FillDirection?, Gap: UDim?): UIListLayout
	local ExistingLayout: Instance? = Target:FindFirstChildOfClass("UIListLayout")
	local Layout: UIListLayout

	if ExistingLayout and ExistingLayout:IsA("UIListLayout") then
		Layout = ExistingLayout
	else
		Layout = Instance.new("UIListLayout")
		Layout.Parent = Target
	end

	Layout.FillDirection = Direction or Enum.FillDirection.Vertical
	Layout.Padding = Gap or Theme.Sizes.Gap
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	return Layout
end

return Theme