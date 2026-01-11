--!strict

local Theme = {}

Theme.Colors = {
	Overlay = Color3.fromRGB(0,0,0),

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

	NodeFlow = Color3.fromRGB(83, 108, 133),
	NodeCombat = Color3.fromRGB(167, 83, 83),
	NodeEffects = Color3.fromRGB(116, 91, 141),
	NodeLogic = Color3.fromRGB(160, 146, 91),
	NodeAdvanced = Color3.fromRGB(78, 138, 123),
	NodeUtility = Color3.fromRGB(90, 90, 95),
	NodeValue = Color3.fromRGB(80, 180, 140),
	NodeBoolean = Color3.fromRGB(180, 100, 100),

	NodeWait = Color3.fromRGB(120, 120, 140),
	NodeAnimation = Color3.fromRGB(180, 120, 200),
	NodeSound = Color3.fromRGB(200, 160, 80),
	NodeVelocity = Color3.fromRGB(80, 160, 200),
	NodeHitbox = Color3.fromRGB(200, 80, 80),
	NodeHitCancel = Color3.fromRGB(200, 120, 80),
	NodeAction = Color3.fromRGB(160, 80, 200),
	NodeBranch = Color3.fromRGB(80, 200, 160),
	NodeSignal = Color3.fromRGB(200, 200, 80),
	NodeGate = Color3.fromRGB(80, 200, 200),
	NodeHealth = Color3.fromRGB(80, 200, 80),

	PortFlow = Color3.fromRGB(200, 200, 200),
	PortSignal = Color3.fromRGB(200, 200, 80),
	PortValue = Color3.fromRGB(80, 200, 160),

	WireFlow = Color3.fromRGB(180, 180, 180),
	WireSignal = Color3.fromRGB(200, 200, 80),
	WireValue = Color3.fromRGB(80, 200, 160),
	WirePreview = Color3.fromRGB(100, 140, 200),

	BranchHeader = Color3.fromRGB(50, 50, 60),
	BranchHeaderEntry = Color3.fromRGB(60, 80, 60),

	SnapHighlight = Color3.fromRGB(140, 200, 255),
	WireSnapped = Color3.fromRGB(220, 240, 255),
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
	SafeAreaTop = 36,
}

Theme.StrokeSizes = {
	Selected = 1,
	Deslected = 1,
}

Theme.Fonts = {
	Default = Font.fromEnum(Enum.Font.GothamMedium),
	Bold = Font.fromEnum(Enum.Font.GothamBold),
	Mono = Font.fromEnum(Enum.Font.RobotoMono),
	Regular = Font.fromEnum(Enum.Font.GothamMedium),
}

Theme.TextSizes = {
	Tiny = 10,
	Small = 12,
	Default = 14,
	Large = 16,
	Header = 18,
}

Theme.ZIndex = {
	Background = 1,
	BranchContainer = 10,
	Wire = 15,
	Node = 20,
	NodeContent = 21,
	Port = 25,
	NodeHeader = 28,
	NodeSelected = 30,
	NodeSelectedContent = 31,
	NodeSelectedHeader = 33,
	WirePreview = 40,
	Panel = 50,
	Dropdown = 90,
	Tooltip = 100,
	Modal = 200,
}

Theme.Assets = {
	GridImage = "rbxassetid://12796647774",
}

function Theme.ApplyCorner(Target: GuiObject, Radius: UDim | number | nil)
	local Corner = Instance.new("UICorner")
	if type(Radius) == "number" then
		Corner.CornerRadius = UDim.new(0, Radius)
	elseif typeof(Radius) == "UDim" then
		Corner.CornerRadius = Radius
	else
		Corner.CornerRadius = Theme.Sizes.BorderRadius
	end
	Corner.Parent = Target
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
	Stroke.Thickness = Thickness or Theme.StrokeSizes.Selected
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return Stroke
end

function Theme.ApplyListLayout(Target: GuiObject, Direction: Enum.FillDirection?, Padding: UDim?)
	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Direction or Enum.FillDirection.Vertical
	Layout.Padding = Padding or Theme.Sizes.Gap
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Target
	return Layout
end

function Theme.ApplyPadding(Target: GuiObject, Padding: UDim?)
	local PaddingObj = Instance.new("UIPadding")
	local PaddingValue = Padding or Theme.Sizes.Padding
	PaddingObj.PaddingTop = PaddingValue
	PaddingObj.PaddingBottom = PaddingValue
	PaddingObj.PaddingLeft = PaddingValue
	PaddingObj.PaddingRight = PaddingValue
	PaddingObj.Parent = Target
	return PaddingObj
end

function Theme.GetPortColor(PortType: string): Color3
	if PortType == "Flow" then
		return Theme.Colors.PortFlow
	elseif PortType == "Signal" then
		return Theme.Colors.PortSignal
	elseif PortType == "Value" then
		return Theme.Colors.PortValue
	end
	return Theme.Colors.PortFlow
end

function Theme.GetWireColor(WireType: string): Color3
	if WireType == "Flow" then
		return Theme.Colors.WireFlow
	elseif WireType == "Signal" then
		return Theme.Colors.WireSignal
	elseif WireType == "Value" then
		return Theme.Colors.WireValue
	end
	return Theme.Colors.WireFlow
end

return Theme