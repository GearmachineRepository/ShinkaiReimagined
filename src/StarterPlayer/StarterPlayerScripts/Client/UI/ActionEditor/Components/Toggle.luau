--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

local Toggle = {}

local TOGGLE_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

export type ToggleConfig = {
	Name: string?,
	Value: boolean?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
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
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = UILibrary.SurfaceContainer({
		Name = Config.Name or "Toggle",
		Size = Config.Size or UDim2.fromOffset(40, 22),
		Position = Config.Position,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	Container.BackgroundColor3 = if CurrentValue then Theme.Colors.Primary else Theme.Colors.BackgroundDark

	local Corner = Container:FindFirstChildOfClass("UICorner")
	if Corner then
		Corner.CornerRadius = UDim.new(0.5, 0)
	end

	local Knob = UILibrary.TransparentContainer({
		Name = "Knob",
		Size = UDim2.fromOffset(16, 16),
		Position = if CurrentValue then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
		ZIndex = BaseZIndex + 1,
		Parent = Container,
	})

	Knob.AnchorPoint = Vector2.new(0, 0.5)
	Knob.BackgroundTransparency = 0
	Knob.BackgroundColor3 = Theme.Colors.Text

	UILibrary.Corner(Knob, UDim.new(0.5, 0))

	local ClickDetector = UILibrary.ClickBlocker({
		Name = "ClickDetector",
		ZIndex = BaseZIndex + 2,
		Parent = Container,
	})

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

	local ToggleInstance: ToggleInstance = {
		Frame = Container,
	} :: any

	function ToggleInstance.GetValue(): boolean
		return CurrentValue
	end

	function ToggleInstance.SetValue(Value: boolean)
		CurrentValue = Value
		UpdateVisual(false)
	end

	function ToggleInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return ToggleInstance
end

return Toggle