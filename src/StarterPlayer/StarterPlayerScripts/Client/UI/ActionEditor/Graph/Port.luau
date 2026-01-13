--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local UILibrary = require(script.Parent.Parent.UILibrary)

local Port = {}

export type PortConfig = {
	Name: string,
	Direction: Types.PortDirection,
	PortType: Types.PortType,
	NodeId: string,
	Parent: Instance?,
	OnConnectionStart: ((PortInstance: PortInstance) -> ())?,
	OnConnectionEnd: ((PortInstance: PortInstance) -> ())?,
	OnHover: ((Hovered: boolean) -> ())?,
	IsDraggingWire: (() -> boolean)?,
}

export type PortInstance = {
	Frame: Frame,
	NodeId: string,
	PortName: string,
	Direction: Types.PortDirection,
	PortType: Types.PortType,
	GetWorldPosition: () -> Vector2,
	SetHighlighted: (Highlighted: boolean) -> (),
	SetConnected: (Connected: boolean) -> (),
	Destroy: () -> (),
}

local INNER_CIRCLE_SCALE = 0.55
local INNER_DARKEN_FACTOR = 0.85

local function DarkenColor(Color: Color3, Factor: number): Color3
	return Color3.new(
		Color.R * Factor,
		Color.G * Factor,
		Color.B * Factor
	)
end

function Port.Create(Config: PortConfig): PortInstance
	local PortColor = Theme.GetPortColor(Config.PortType)
	local _IsConnected = false
	local _IsHighlighted = false

	local Container = Instance.new("Frame")
	Container.Name = "Port_" .. Config.Name
	Container.Size = UDim2.new(1, 0, 0, Theme.Sizes.NodePortHeight)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	Container.ZIndex = Theme.ZIndex.Port

	local PortCircle = Instance.new("Frame")
	PortCircle.Name = "Circle"
	PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2, Theme.Sizes.NodePortRadius * 2)
	PortCircle.BackgroundColor3 = PortColor
	PortCircle.BorderSizePixel = 0
	PortCircle.ZIndex = Theme.ZIndex.Port
	PortCircle.Parent = Container

	UILibrary.Corner(PortCircle, UDim.new(0.5, 0))

	local PortInnerCircle = Instance.new("Frame")
	PortInnerCircle.Name = "InnerCircle"
	PortInnerCircle.Size = UDim2.fromScale(INNER_CIRCLE_SCALE, INNER_CIRCLE_SCALE)
	PortInnerCircle.Position = UDim2.fromScale(0.5, 0.5)
	PortInnerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	PortInnerCircle.BackgroundColor3 = DarkenColor(PortColor, INNER_DARKEN_FACTOR)
	PortInnerCircle.BorderSizePixel = 0
	PortInnerCircle.ZIndex = Theme.ZIndex.Port + 2
	PortInnerCircle.Parent = PortCircle

	UILibrary.Corner(PortInnerCircle, UDim.new(0.5, 0))

	local PortLabel = Instance.new("TextLabel")
	PortLabel.Name = "Label"
	PortLabel.Size = UDim2.new(1, -24, 1, 0)
	PortLabel.BackgroundTransparency = 1
	PortLabel.Text = Config.Name
	PortLabel.TextColor3 = Theme.Colors.Text
	PortLabel.FontFace = Theme.Fonts.Default
	PortLabel.TextSize = Theme.TextSizes.Small
	PortLabel.ZIndex = Theme.ZIndex.Port

	local HalvedPortRadius = Theme.Sizes.NodePortRadius / 2

	if Config.Direction == "Input" then
		PortLabel.Position = UDim2.fromOffset(8, 0)
		PortLabel.TextXAlignment = Enum.TextXAlignment.Left

		PortCircle.Position = UDim2.new(0, -HalvedPortRadius, 0.5, 0)
		PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	else
		PortLabel.Position = UDim2.fromOffset(-8, 0)
		PortLabel.Size = UDim2.new(1, -8, 1, 0)
		PortLabel.TextXAlignment = Enum.TextXAlignment.Right

		PortCircle.Position = UDim2.new(1, HalvedPortRadius, 0.5, 0)
		PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	end

	PortLabel.Parent = Container

	local ClickDetector = Instance.new("TextButton")
	ClickDetector.Name = "ClickDetector"
	ClickDetector.Size = UDim2.fromOffset(24, Theme.Sizes.NodePortHeight)
	ClickDetector.BackgroundTransparency = 1
	ClickDetector.Text = ""
	ClickDetector.ZIndex = Theme.ZIndex.Port + 5

	if Config.Direction == "Input" then
		ClickDetector.Position = UDim2.fromOffset(-HalvedPortRadius - 6, 0)
	else
		ClickDetector.Position = UDim2.new(1, -12, 0, 0)
	end
	ClickDetector.Parent = Container

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, ClickDetector.MouseButton1Down:Connect(function()
		if Config.OnConnectionStart then
			Config.OnConnectionStart(nil :: any)
		end
	end))

	table.insert(Connections, ClickDetector.MouseButton1Up:Connect(function()
		if Config.OnConnectionEnd then
			Config.OnConnectionEnd(nil :: any)
		end
	end))

	table.insert(Connections, ClickDetector.MouseEnter:Connect(function()
		if Config.OnHover then
			Config.OnHover(true)
		end
		PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2.5, Theme.Sizes.NodePortRadius * 2.5)
	end))

	table.insert(Connections, ClickDetector.MouseLeave:Connect(function()
		if Config.OnHover then
			Config.OnHover(false)
		end
		PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2, Theme.Sizes.NodePortRadius * 2)
	end))

	local PortInstance: PortInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		PortName = Config.Name,
		Direction = Config.Direction,
		PortType = Config.PortType,
	} :: any

	function PortInstance.GetWorldPosition(): Vector2
		local CirclePosition = PortCircle.AbsolutePosition
		local CircleSize = PortCircle.AbsoluteSize
		return CirclePosition + (CircleSize / 2)
	end

	function PortInstance.SetHighlighted(Highlighted: boolean)
		_IsHighlighted = Highlighted
		if Highlighted then
			PortCircle.BackgroundColor3 = Theme.Colors.BorderFocus
			PortInnerCircle.BackgroundColor3 = DarkenColor(PortCircle.BackgroundColor3, INNER_DARKEN_FACTOR)
		else
			PortCircle.BackgroundColor3 = PortColor
			PortInnerCircle.BackgroundColor3 = DarkenColor(PortColor, INNER_DARKEN_FACTOR)
		end
	end

	function PortInstance.SetConnected(Connected: boolean)
		_IsConnected = Connected
	end

	function PortInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return PortInstance
end

return Port