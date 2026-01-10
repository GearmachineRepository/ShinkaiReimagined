--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)

local NumberInput = {}

export type NumberInputConfig = {
	Name: string?,
	Value: number?,
	Min: number?,
	Max: number?,
	Step: number?,
	Precision: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: GuiObject?,
	OnChanged: ((Value: number) -> ())?,
}

export type NumberInputInstance = {
	Frame: Frame,
	GetValue: () -> number,
	SetValue: (Value: number) -> (),
	SetRange: (Min: number, Max: number) -> (),
	Destroy: () -> (),
}

function NumberInput.Create(Config: NumberInputConfig): NumberInputInstance
	local CurrentValue = Config.Value or 0
	local MinValue = Config.Min or -math.huge
	local MaxValue = Config.Max or math.huge
	local StepValue = Config.Step or 1
	local Precision = Config.Precision or 2
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "NumberInput"
	Container.Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Container.BackgroundColor3 = Theme.Colors.BackgroundDark
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Config.LayoutOrder or 0
	Container.ZIndex = BaseZIndex

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusSmall)
	local Stroke = Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Input = Instance.new("TextBox")
	Input.Name = "Input"
	Input.Size = UDim2.new(1, -12, 1, 0)
	Input.Position = UDim2.fromOffset(6, 0)
	Input.BackgroundTransparency = 1
	Input.Text = tostring(CurrentValue)
	Input.TextColor3 = Theme.Colors.Text
	Input.FontFace = Theme.Fonts.Mono
	Input.TextSize = Theme.TextSizes.Default
	Input.TextXAlignment = Enum.TextXAlignment.Left
	Input.ClearTextOnFocus = false
	Input.ZIndex = BaseZIndex + 1
	Input.Parent = Container

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}
	local IsDragging = false
	local DragStartValue = 0
	local DragStartY = 0

	local function FormatValue(Value: number): string
		if Precision == 0 then
			return tostring(math.round(Value))
		end
		return string.format("%." .. Precision .. "f", Value)
	end

	local function ClampValue(Value: number): number
		return math.clamp(Value, MinValue, MaxValue)
	end

	local function SetValueInternal(Value: number, TriggerCallback: boolean)
		local ClampedValue = ClampValue(Value)
		CurrentValue = ClampedValue
		Input.Text = FormatValue(ClampedValue)

		if TriggerCallback and Config.OnChanged then
			Config.OnChanged(ClampedValue)
		end
	end

	table.insert(Connections, Input.Focused:Connect(function()
		Stroke.Color = Theme.Colors.BorderFocus
	end))

	table.insert(Connections, Input.FocusLost:Connect(function()
		Stroke.Color = Theme.Colors.Border
		local ParsedValue = tonumber(Input.Text)
		if ParsedValue then
			SetValueInternal(ParsedValue, true)
		else
			Input.Text = FormatValue(CurrentValue)
		end
	end))

	table.insert(Connections, Container.InputBegan:Connect(function(InputObject: InputObject)
		if InputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if Input:IsFocused() then
			return
		end

		IsDragging = true
		DragStartValue = CurrentValue
		DragStartY = InputObject.Position.Y
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(InputObject: InputObject)
		if not IsDragging then
			return
		end
		if InputObject.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local DeltaY = DragStartY - InputObject.Position.Y
		local StepCount = math.floor(DeltaY / 5)
		local NewValue = DragStartValue + (StepCount * StepValue)
		SetValueInternal(NewValue, true)
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(InputObject: InputObject)
		if InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = false
		end
	end))

	local Instance = {
		Frame = Container,
	}

	function Instance.GetValue(): number
		return CurrentValue
	end

	function Instance.SetValue(Value: number)
		SetValueInternal(Value, false)
	end

	function Instance.SetRange(Min: number, Max: number)
		MinValue = Min
		MaxValue = Max
		SetValueInternal(CurrentValue, false)
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

return NumberInput