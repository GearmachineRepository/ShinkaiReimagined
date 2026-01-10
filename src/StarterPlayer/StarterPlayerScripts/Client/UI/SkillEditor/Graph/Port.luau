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

	local Container = Instance.new("Frame")
	Container.Name = "Port_" .. Config.Name
	Container.Size = UDim2.fromOffset(Theme.Sizes.NodePortHeight, Theme.Sizes.NodePortHeight)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0

	local PortCircle = Instance.new("Frame")
	PortCircle.Name = "Circle"
	PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2, Theme.Sizes.NodePortRadius * 2)
	PortCircle.Position = UDim2.fromScale(0.5, 0.5)
	PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	PortCircle.BackgroundColor3 = PortColor
	PortCircle.BorderSizePixel = 0
	PortCircle.Parent = Container

	Theme.ApplyCorner(PortCircle, UDim.new(0.5, 0))
	Theme.ApplyStroke(PortCircle, Theme.Colors.Border, 2)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Theme.Colors.TextMuted
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.Text = Config.Name
	Label.Parent = Container

	if Config.Direction == "Input" then
		Label.Size = UDim2.new(0, 60, 1, 0)
		Label.Position = UDim2.new(1, 4, 0, 0)
		Label.TextXAlignment = Enum.TextXAlignment.Left
	else
		Label.Size = UDim2.new(0, 60, 1, 0)
		Label.Position = UDim2.fromOffset(-64, 0)
		Label.TextXAlignment = Enum.TextXAlignment.Right
	end

	local ClickDetector = Instance.new("TextButton")
	ClickDetector.Name = "ClickDetector"
	ClickDetector.Size = UDim2.fromScale(1, 1)
	ClickDetector.BackgroundTransparency = 1
	ClickDetector.Text = ""
	ClickDetector.ZIndex = Theme.ZIndex.Port
	ClickDetector.Parent = Container

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, ClickDetector.MouseEnter:Connect(function()
		PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2.5, Theme.Sizes.NodePortRadius * 2.5)
		if Config.OnHover then
			Config.OnHover(true)
		end
	end))

	table.insert(Connections, ClickDetector.MouseLeave:Connect(function()
		PortCircle.Size = UDim2.fromOffset(Theme.Sizes.NodePortRadius * 2, Theme.Sizes.NodePortRadius * 2)
		if Config.OnHover then
			Config.OnHover(false)
		end
	end))

	table.insert(Connections, ClickDetector.MouseButton1Down:Connect(function()
		if Config.OnConnectionStart then
			Config.OnConnectionStart(Instance :: any)
		end
	end))

	table.insert(Connections, ClickDetector.MouseButton1Up:Connect(function()
		if Config.OnConnectionEnd then
			Config.OnConnectionEnd(Instance :: any)
		end
	end))

	local Instance: PortInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		PortName = Config.Name,
		Direction = Config.Direction,
		PortType = Config.PortType,
	} :: any

	function Instance.GetWorldPosition(): Vector2
		local AbsolutePosition = PortCircle.AbsolutePosition
		local AbsoluteSize = PortCircle.AbsoluteSize
		return AbsolutePosition + (AbsoluteSize / 2)
	end

	function Instance.SetHighlighted(Highlighted: boolean)
		if Highlighted then
			local Stroke = PortCircle:FindFirstChildOfClass("UIStroke")
			if Stroke then
				Stroke.Color = Theme.Colors.BorderFocus
				Stroke.Thickness = 3
			end
		else
			local Stroke = PortCircle:FindFirstChildOfClass("UIStroke")
			if Stroke then
				Stroke.Color = Theme.Colors.Border
				Stroke.Thickness = 2
			end
		end
	end

	function Instance.SetConnected(Connected: boolean)
		if Connected then
			PortCircle.BackgroundColor3 = PortColor
		else
			PortCircle.BackgroundColor3 = Theme.Colors.BackgroundDark
		end
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