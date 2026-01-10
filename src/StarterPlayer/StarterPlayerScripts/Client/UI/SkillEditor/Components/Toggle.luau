--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)

local Toggle = {}

local TOGGLE_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type ToggleConfig = {
	Name: string?,
	Value: boolean?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	Parent: GuiObject?,
	OnChanged: ((Value: boolean) -> ())?,
}

export type ToggleInstance = {
	Frame: Frame,
	GetValue: () -> boolean,
	SetValue: (Value: boolean) -> (),
	Destroy: () -> (),
}

function Toggle.Create(Config: ToggleConfig): ToggleInstance
	local CurrentValue = Config.Value or false

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "Toggle"
	Container.Size = Config.Size or UDim2.fromOffset(40, 22)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Container.BackgroundColor3 = if CurrentValue then Theme.Colors.Primary else Theme.Colors.BackgroundDark
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Config.LayoutOrder or 0

	Theme.ApplyCorner(Container, UDim.new(0.5, 0))
	Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Knob = Instance.new("Frame")
	Knob.Name = "Knob"
	Knob.Size = UDim2.fromOffset(16, 16)
	Knob.Position = if CurrentValue then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
	Knob.AnchorPoint = Vector2.new(0, 0.5)
	Knob.BackgroundColor3 = Theme.Colors.Text
	Knob.BorderSizePixel = 0
	Knob.Parent = Container

	Theme.ApplyCorner(Knob, UDim.new(0.5, 0))

	local ClickDetector = Instance.new("TextButton")
	ClickDetector.Name = "ClickDetector"
	ClickDetector.Size = UDim2.fromScale(1, 1)
	ClickDetector.BackgroundTransparency = 1
	ClickDetector.Text = ""
	ClickDetector.Parent = Container

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}

	local function UpdateVisual(Animate: boolean)
		local TargetPosition = if CurrentValue then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
		local TargetColor = if CurrentValue then Theme.Colors.Primary else Theme.Colors.BackgroundDark

		if Animate then
			TweenService:Create(Knob, TOGGLE_TWEEN_INFO, { Position = TargetPosition }):Play()
			TweenService:Create(Container, TOGGLE_TWEEN_INFO, { BackgroundColor3 = TargetColor }):Play()
		else
			Knob.Position = TargetPosition
			Container.BackgroundColor3 = TargetColor
		end
	end

	table.insert(Connections, ClickDetector.MouseButton1Click:Connect(function()
		CurrentValue = not CurrentValue
		UpdateVisual(true)

		if Config.OnChanged then
			Config.OnChanged(CurrentValue)
		end
	end))

	local Instance = {
		Frame = Container,
	}

	function Instance.GetValue(): boolean
		return CurrentValue
	end

	function Instance.SetValue(Value: boolean)
		if CurrentValue == Value then
			return
		end
		CurrentValue = Value
		UpdateVisual(false)
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

return Toggle