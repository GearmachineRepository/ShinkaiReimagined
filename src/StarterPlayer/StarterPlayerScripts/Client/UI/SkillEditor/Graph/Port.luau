--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local Port = {}

export type PortConfig = {
	Name: string,
	Direction: Types.PortDirection,
	PortType: Types.PortType,
	NodeId: string,
	Parent: GuiObject?,
	OnConnectionStart: ((PortInstance: PortInstance) -> ())?,
	OnConnectionEnd: ((PortInstance: PortInstance) -> ())?,
	OnHover: ((Hovered: boolean) -> ())?,
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

function Port.Create(Config: PortConfig): PortInstance
	local PortColor = if Config.PortType == "Flow" then Theme.Colors.PortFlow else Theme.Colors.PortSignal
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

	if Config.Direction == "Input" then
		PortCircle.Position = UDim2.new(0, 4, 0.5, 0)
		PortCircle.AnchorPoint = Vector2.new(0, 0.5)
	else
		PortCircle.Position = UDim2.new(1, -4, 0.5, 0)
		PortCircle.AnchorPoint = Vector2.new(1, 0.5)
	end
	PortCircle.Parent = Container

	Theme.ApplyCorner(PortCircle, UDim.new(0.5, 0))

	local PortLabel = Instance.new("TextLabel")
	PortLabel.Name = "Label"
	PortLabel.Size = UDim2.new(1, -24, 1, 0)
	PortLabel.BackgroundTransparency = 1
	PortLabel.Text = Config.Name
	PortLabel.TextColor3 = Theme.Colors.Text
	PortLabel.FontFace = Theme.Fonts.Default
	PortLabel.TextSize = Theme.TextSizes.Small
	PortLabel.ZIndex = Theme.ZIndex.Port

	local HalvedPortRadius = Theme.Sizes.NodePortRadius/2

	if Config.Direction == "Input" then
		PortLabel.Position = UDim2.fromOffset(8, 0)
		PortLabel.TextXAlignment = Enum.TextXAlignment.Left
	else
		PortLabel.Position = UDim2.fromOffset(-8, 0)
		PortLabel.Size = UDim2.new(1, -8, 1, 0)
		PortLabel.TextXAlignment = Enum.TextXAlignment.Right
	end

	if Config.Direction == "Input" then
		PortCircle.Position = UDim2.new(0, -HalvedPortRadius, 0.5, 0)
		PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	else
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

	local Instance: PortInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		PortName = Config.Name,
		Direction = Config.Direction,
		PortType = Config.PortType,
	} :: any

	function Instance.GetWorldPosition(): Vector2
		local CirclePosition = PortCircle.AbsolutePosition
		local CircleSize = PortCircle.AbsoluteSize
		return CirclePosition + (CircleSize / 2)
	end

	function Instance.SetHighlighted(Highlighted: boolean)
		_IsHighlighted = Highlighted
		if Highlighted then
			PortCircle.BackgroundColor3 = Theme.Colors.BorderFocus
		else
			PortCircle.BackgroundColor3 = PortColor
		end
	end

	function Instance.SetConnected(Connected: boolean)
		_IsConnected = Connected
	end

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

return Port