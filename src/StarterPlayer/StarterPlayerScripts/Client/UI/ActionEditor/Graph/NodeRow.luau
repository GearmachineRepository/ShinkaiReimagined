--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local InlineControls = require(script.Parent.InlineControls)

local NodeRow = {}

local ROW_HEIGHT = 22
local PORT_RADIUS = 6
local INNER_CIRCLE_SCALE = 0.55
local INNER_DARKEN_FACTOR = 0.85

export type RowType = "InputPort" | "OutputPort" | "PropertyOnly"

export type RowConfig = {
	RowType: RowType,
	NodeId: string,
	PortName: string?,
	PortType: Types.PortType?,
	PropertyDef: Types.PropertyDefinition?,
	PropertyValue: any?,
	IsWired: boolean?,
	Parent: GuiObject?,
	ZIndex: number?,
	OnConnectionStart: ((NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection) -> ())?,
	OnConnectionEnd: ((NodeId: string, PortName: string) -> ())?,
	OnPropertyChanged: ((Key: string, Value: any) -> ())?,
}

export type RowInstance = {
	Frame: Frame,
	NodeId: string,
	PortName: string?,
	Direction: Types.PortDirection?,
	PortType: Types.PortType?,
	PropertyKey: string?,
	GetWorldPosition: () -> Vector2?,
	SetWired: (Wired: boolean) -> (),
	SetPropertyValue: (Value: any) -> (),
	GetPropertyValue: () -> any?,
	SetHighlighted: (Highlighted: boolean) -> (),
	SetZIndex: (ZIndex: number) -> (),
	Destroy: () -> (),
}

local function DarkenColor(Color: Color3, Factor: number): Color3
	return Color3.new(
		Color.R * Factor,
		Color.G * Factor,
		Color.B * Factor
	)
end

function NodeRow.Create(Config: RowConfig): RowInstance
	local IsWired = Config.IsWired or false
	local CurrentPropertyValue = Config.PropertyValue
	local InlineControl: InlineControls.ControlInstance? = nil
	local PortCircle: Frame? = nil
	local Connections: { RBXScriptConnection } = {}

	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent
	local Direction: Types.PortDirection? = nil

	if Config.RowType == "InputPort" then
		Direction = "Input"
	elseif Config.RowType == "OutputPort" then
		Direction = "Output"
	end

	local Container = Instance.new("Frame")
	Container.Name = "Row_" .. (Config.PortName or Config.PropertyDef and Config.PropertyDef.Key or "Unknown")
	Container.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	Container.ZIndex = CurrentZIndex
	Container.ClipsDescendants = false

	local PortColor = Theme.GetPortColor(Config.PortType or "Flow")
	local ClickDetector: TextButton? = nil

	if Config.RowType == "InputPort" or Config.RowType == "OutputPort" then
		PortCircle = Instance.new("Frame")
		PortCircle.Name = "Circle"
		PortCircle.Size = UDim2.fromOffset(PORT_RADIUS * 2, PORT_RADIUS * 2)
		PortCircle.BackgroundColor3 = PortColor
		PortCircle.BorderSizePixel = 0
		PortCircle.ZIndex = CurrentZIndex + 2
		PortCircle.Parent = Container

		Theme.ApplyCorner(PortCircle, UDim.new(0.5, 0))

		local InnerCircle = Instance.new("Frame")
		InnerCircle.Name = "InnerCircle"
		InnerCircle.Size = UDim2.fromScale(INNER_CIRCLE_SCALE, INNER_CIRCLE_SCALE)
		InnerCircle.Position = UDim2.fromScale(0.5, 0.5)
		InnerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		InnerCircle.BackgroundColor3 = DarkenColor(PortColor, INNER_DARKEN_FACTOR)
		InnerCircle.BorderSizePixel = 0
		InnerCircle.ZIndex = CurrentZIndex + 3
		InnerCircle.Parent = PortCircle

		Theme.ApplyCorner(InnerCircle, UDim.new(0.5, 0))

		local HalfRadius = PORT_RADIUS / 2
		if Direction == "Input" then
			PortCircle.Position = UDim2.new(0, -HalfRadius, 0.5, 0)
			PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		else
			PortCircle.Position = UDim2.new(1, HalfRadius, 0.5, 0)
			PortCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		end

		ClickDetector = Instance.new("TextButton")
		ClickDetector.Name = "PortClick"
		ClickDetector.Size = UDim2.fromOffset(24, ROW_HEIGHT)
		ClickDetector.BackgroundTransparency = 1
		ClickDetector.Text = ""
		ClickDetector.ZIndex = CurrentZIndex + 5

		if Direction == "Input" then
			ClickDetector.Position = UDim2.fromOffset(-PORT_RADIUS - 6, 0)
		else
			ClickDetector.Position = UDim2.new(1, -12, 0, 0)
		end
		ClickDetector.Parent = Container

		table.insert(Connections, ClickDetector.MouseButton1Down:Connect(function()
			if Config.OnConnectionStart and Config.PortName and Config.PortType then
				Config.OnConnectionStart(Config.NodeId, Config.PortName, Config.PortType, Direction :: Types.PortDirection)
			end
		end))

		table.insert(Connections, ClickDetector.MouseButton1Up:Connect(function()
			if Config.OnConnectionEnd and Config.PortName then
				Config.OnConnectionEnd(Config.NodeId, Config.PortName)
			end
		end))

		table.insert(Connections, ClickDetector.MouseEnter:Connect(function()
			if PortCircle then
				PortCircle.Size = UDim2.fromOffset(PORT_RADIUS * 2.5, PORT_RADIUS * 2.5)
			end
		end))

		table.insert(Connections, ClickDetector.MouseLeave:Connect(function()
			if PortCircle then
				PortCircle.Size = UDim2.fromOffset(PORT_RADIUS * 2, PORT_RADIUS * 2)
			end
		end))
	end

	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "Content"
	ContentArea.BackgroundTransparency = 1
	ContentArea.ZIndex = CurrentZIndex

	if Config.RowType == "InputPort" then
		ContentArea.Size = UDim2.new(1, -8, 1, 0)
		ContentArea.Position = UDim2.fromOffset(8, 0)
	elseif Config.RowType == "OutputPort" then
		ContentArea.Size = UDim2.new(1, -8, 1, 0)
		ContentArea.Position = UDim2.fromOffset(0, 0)
	else
		ContentArea.Size = UDim2.new(1, -8, 1, 0)
		ContentArea.Position = UDim2.fromOffset(4, 0)
	end
	ContentArea.Parent = Container

	local HasInlineProperty = Config.PropertyDef ~= nil and Config.RowType ~= "OutputPort"

	local WiredIndicator: TextLabel? = nil
	local Label: TextLabel? = nil
	local ControlContainer: Frame? = nil

	if Config.RowType == "InputPort" and HasInlineProperty then
		ControlContainer = Instance.new("Frame")
		ControlContainer.Name = "ControlContainer"
		ControlContainer.Size = UDim2.new(1, 0, 1, 0)
		ControlContainer.Position = UDim2.fromScale(0, 0)
		ControlContainer.BackgroundTransparency = 1
		ControlContainer.ZIndex = CurrentZIndex
		ControlContainer.Parent = ContentArea

		WiredIndicator = Instance.new("TextLabel")
		WiredIndicator.Name = "WiredIndicator"
		WiredIndicator.Size = UDim2.new(1, 0, 1, 0)
		WiredIndicator.Position = UDim2.fromScale(0, 0)
		WiredIndicator.BackgroundTransparency = 1
		WiredIndicator.Text = "← " .. (Config.PropertyDef and Config.PropertyDef.Label or Config.PortName or "")
		WiredIndicator.TextColor3 = Theme.Colors.TextMuted
		WiredIndicator.FontFace = Theme.Fonts.Default
		WiredIndicator.TextSize = Theme.TextSizes.Small
		WiredIndicator.TextXAlignment = Enum.TextXAlignment.Left
		WiredIndicator.ZIndex = CurrentZIndex + 1
		WiredIndicator.Visible = false
		WiredIndicator.Parent = ContentArea

		if Config.PropertyDef and Config.OnPropertyChanged then
			InlineControl = InlineControls.Create({
				PropertyDef = Config.PropertyDef,
				Value = CurrentPropertyValue,
				OnChanged = function(NewValue: any)
					CurrentPropertyValue = NewValue
					if Config.OnPropertyChanged and Config.PropertyDef then
						Config.OnPropertyChanged(Config.PropertyDef.Key, NewValue)
					end
				end,
				Parent = ControlContainer,
				ZIndex = CurrentZIndex + 1,
				Disabled = IsWired,
			})
		end

	elseif Config.RowType == "OutputPort" then
		Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, -4, 1, 0)
		Label.Position = UDim2.fromOffset(0, 0)
		Label.BackgroundTransparency = 1
		Label.Text = Config.PortName or ""
		Label.TextColor3 = Theme.Colors.Text
		Label.FontFace = Theme.Fonts.Default
		Label.TextSize = Theme.TextSizes.Small
		Label.TextXAlignment = Enum.TextXAlignment.Right
		Label.TextTruncate = Enum.TextTruncate.AtEnd
		Label.ZIndex = CurrentZIndex + 1
		Label.Parent = ContentArea

	elseif Config.RowType == "PropertyOnly" and Config.PropertyDef then
		ControlContainer = Instance.new("Frame")
		ControlContainer.Name = "ControlContainer"
		ControlContainer.Size = UDim2.new(1, 0, 1, 0)
		ControlContainer.Position = UDim2.fromScale(0, 0)
		ControlContainer.BackgroundTransparency = 1
		ControlContainer.ZIndex = CurrentZIndex
		ControlContainer.Parent = ContentArea

		if Config.OnPropertyChanged then
			InlineControl = InlineControls.Create({
				PropertyDef = Config.PropertyDef,
				Value = CurrentPropertyValue,
				OnChanged = function(NewValue: any)
					CurrentPropertyValue = NewValue
					if Config.OnPropertyChanged then
						Config.OnPropertyChanged(Config.PropertyDef.Key, NewValue)
					end
				end,
				Parent = ControlContainer,
				ZIndex = CurrentZIndex + 1,
			})
		end

	elseif Config.RowType == "InputPort" then
		Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, -4, 1, 0)
		Label.Position = UDim2.fromOffset(0, 0)
		Label.BackgroundTransparency = 1
		Label.Text = Config.PortName or ""
		Label.TextColor3 = Theme.Colors.Text
		Label.FontFace = Theme.Fonts.Default
		Label.TextSize = Theme.TextSizes.Small
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.TextTruncate = Enum.TextTruncate.AtEnd
		Label.ZIndex = CurrentZIndex + 1
		Label.Parent = ContentArea
	end

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local function UpdateWiredState()
		if WiredIndicator then
			WiredIndicator.Visible = IsWired
		end
		if ControlContainer then
			ControlContainer.Visible = not IsWired
		end
		if InlineControl then
			InlineControl.SetDisabled(IsWired)
		end
	end

	UpdateWiredState()

	local RowInstance: RowInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		PortName = Config.PortName,
		Direction = Direction,
		PortType = Config.PortType,
		PropertyKey = Config.PropertyDef and Config.PropertyDef.Key or nil,
	} :: any

	function RowInstance.GetWorldPosition(): Vector2?
		if PortCircle then
			local Pos = PortCircle.AbsolutePosition
			local Size = PortCircle.AbsoluteSize
			return Pos + (Size / 2)
		end
		return nil
	end

	function RowInstance.SetWired(Wired: boolean)
		IsWired = Wired
		UpdateWiredState()
	end

	function RowInstance.SetPropertyValue(Value: any)
		CurrentPropertyValue = Value
		if InlineControl then
			InlineControl.SetValue(Value)
		end
	end

	function RowInstance.GetPropertyValue(): any?
		if InlineControl then
			return InlineControl.GetValue()
		end
		return CurrentPropertyValue
	end

	function RowInstance.SetHighlighted(Highlighted: boolean)
		if PortCircle then
			if Highlighted then
				PortCircle.BackgroundColor3 = Theme.Colors.BorderFocus
				local Inner = PortCircle:FindFirstChild("InnerCircle") :: Frame?
				if Inner then
					Inner.BackgroundColor3 = DarkenColor(Theme.Colors.BorderFocus, INNER_DARKEN_FACTOR)
				end
				PortCircle.Size = UDim2.fromOffset(PORT_RADIUS * 2.5, PORT_RADIUS * 2.5)
			else
				PortCircle.BackgroundColor3 = PortColor
				local Inner = PortCircle:FindFirstChild("InnerCircle") :: Frame?
				if Inner then
					Inner.BackgroundColor3 = DarkenColor(PortColor, INNER_DARKEN_FACTOR)
				end
				PortCircle.Size = UDim2.fromOffset(PORT_RADIUS * 2, PORT_RADIUS * 2)
			end
		end
	end

	function RowInstance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		ContentArea.ZIndex = ZIndex

		if PortCircle then
			PortCircle.ZIndex = ZIndex + 2
			local Inner = PortCircle:FindFirstChild("InnerCircle")
			if Inner and Inner:IsA("GuiObject") then
				Inner.ZIndex = ZIndex + 3
			end
		end

		if ClickDetector then
			ClickDetector.ZIndex = ZIndex + 5
		end

		if ControlContainer then
			ControlContainer.ZIndex = ZIndex
		end

		if WiredIndicator then
			WiredIndicator.ZIndex = ZIndex + 1
		end

		if Label then
			Label.ZIndex = ZIndex + 1
		end

		if InlineControl then
			InlineControl.SetZIndex(ZIndex + 1)
		end
	end

	function RowInstance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)

		if InlineControl then
			InlineControl.Destroy()
		end

		Container:Destroy()
	end

	return RowInstance
end

return NodeRow