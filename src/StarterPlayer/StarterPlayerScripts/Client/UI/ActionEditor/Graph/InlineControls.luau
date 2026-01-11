--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local InlineControls = {}

local CONTROL_HEIGHT = 18
local CONTROL_PADDING = 4
local CHECKBOX_SIZE = 14

export type ControlConfig = {
	PropertyDef: Types.PropertyDefinition,
	Value: any,
	OnChanged: (NewValue: any) -> (),
	Parent: GuiObject,
	ZIndex: number?,
	Disabled: boolean?,
}

export type ControlInstance = {
	Frame: Frame,
	GetValue: () -> any,
	SetValue: (Value: any) -> (),
	SetDisabled: (Disabled: boolean) -> (),
	SetZIndex: (ZIndex: number) -> (),
	Destroy: () -> (),
}

local function CreateBaseContainer(Config: ControlConfig): Frame
	local Container = Instance.new("Frame")
	Container.Name = "Control_" .. Config.PropertyDef.Key
	Container.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	Container.ZIndex = Config.ZIndex or Theme.ZIndex.NodeContent
	Container.Parent = Config.Parent

	return Container
end

function InlineControls.CreateNumber(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or 0
	local IsDisabled = Config.Disabled or false
	local IsFocused = false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(0.45, 0, 1, 0)
	Label.Position = UDim2.fromScale(0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Config.PropertyDef.Label
	Label.TextColor3 = Theme.Colors.TextMuted
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextTruncate = Enum.TextTruncate.AtEnd
	Label.ZIndex = CurrentZIndex + 1
	Label.Parent = Container

	local ValueBackground = Instance.new("Frame")
	ValueBackground.Name = "ValueBg"
	ValueBackground.Size = UDim2.new(0.53, 0, 1, 0)
	ValueBackground.Position = UDim2.new(0.47, 0, 0, 0)
	ValueBackground.BackgroundColor3 = Theme.Colors.BackgroundDark
	ValueBackground.BorderSizePixel = 0
	ValueBackground.ZIndex = CurrentZIndex
	ValueBackground.Parent = Container

	Theme.ApplyCorner(ValueBackground, UDim.new(0, 3))

	local TextBox = Instance.new("TextBox")
	TextBox.Name = "Input"
	TextBox.Size = UDim2.new(1, -CONTROL_PADDING * 2, 1, 0)
	TextBox.Position = UDim2.fromOffset(CONTROL_PADDING, 0)
	TextBox.BackgroundTransparency = 1
	TextBox.Text = tostring(CurrentValue)
	TextBox.TextColor3 = Theme.Colors.Text
	TextBox.PlaceholderColor3 = Theme.Colors.TextMuted
	TextBox.FontFace = Theme.Fonts.Mono
	TextBox.TextSize = Theme.TextSizes.Small
	TextBox.TextXAlignment = Enum.TextXAlignment.Center
	TextBox.ClearTextOnFocus = false
	TextBox.ZIndex = CurrentZIndex + 2
	TextBox.Parent = ValueBackground

	local function UpdateDisplay()
		if not IsFocused then
			if math.floor(CurrentValue) == CurrentValue then
				TextBox.Text = tostring(CurrentValue)
			else
				TextBox.Text = string.format("%.2f", CurrentValue)
			end
		end
	end

	local function SetFocusedLayout(Focused: boolean)
		IsFocused = Focused
		if Focused then
			Label.Visible = false
			ValueBackground.Size = UDim2.new(1, 0, 1, 0)
			ValueBackground.Position = UDim2.fromScale(0, 0)
		else
			Label.Visible = true
			ValueBackground.Size = UDim2.new(0.53, 0, 1, 0)
			ValueBackground.Position = UDim2.new(0.47, 0, 0, 0)
			UpdateDisplay()
		end
	end

	local function ApplyValue(Text: string)
		local Num = tonumber(Text)
		if Num then
			local Min = Config.PropertyDef.Min or -9999
			local Max = Config.PropertyDef.Max or 9999
			Num = math.clamp(Num, Min, Max)
			CurrentValue = Num
			UpdateDisplay()
			Config.OnChanged(CurrentValue)
		else
			UpdateDisplay()
		end
	end

	table.insert(Connections, TextBox.Focused:Connect(function()
		if not IsDisabled then
			SetFocusedLayout(true)
		end
	end))

	table.insert(Connections, TextBox.FocusLost:Connect(function(EnterPressed: boolean)
		ApplyValue(TextBox.Text)
		SetFocusedLayout(false)
	end))

	local DragConnection: RBXScriptConnection? = nil
	local DragStartValue = 0
	local DragStartX = 0
	local IsDragging = false

	table.insert(Connections, ValueBackground.InputBegan:Connect(function(Input: InputObject)
		if IsDisabled then
			return
		end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and not TextBox:IsFocused() then
			IsDragging = true
			DragStartValue = CurrentValue
			DragStartX = Input.Position.X

			DragConnection = UserInputService.InputChanged:Connect(function(MoveInput: InputObject)
				if MoveInput.UserInputType == Enum.UserInputType.MouseMovement and IsDragging then
					local Delta = MoveInput.Position.X - DragStartX
					local Sensitivity = 0.1
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						Sensitivity = 0.01
					elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
						Sensitivity = 1
					end

					local NewValue = DragStartValue + (Delta * Sensitivity)
					local Min = Config.PropertyDef.Min or -9999
					local Max = Config.PropertyDef.Max or 9999
					NewValue = math.clamp(NewValue, Min, Max)

					CurrentValue = NewValue
					UpdateDisplay()
					Config.OnChanged(CurrentValue)
				end
			end)
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = false
			if DragConnection then
				DragConnection:Disconnect()
				DragConnection = nil
			end
		end
	end))

	UpdateDisplay()

	local Instance: ControlInstance = {
		Frame = Container,
	} :: any

	function Instance.GetValue(): any
		return CurrentValue
	end

	function Instance.SetValue(Value: any)
		CurrentValue = Value or 0
		UpdateDisplay()
	end

	function Instance.SetDisabled(Disabled: boolean)
		IsDisabled = Disabled
		TextBox.TextEditable = not Disabled
		ValueBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		TextBox.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
	end

	function Instance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Label.ZIndex = ZIndex + 1
		ValueBackground.ZIndex = ZIndex
		TextBox.ZIndex = ZIndex + 2
	end

	function Instance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		if DragConnection then
			DragConnection:Disconnect()
		end
		Container:Destroy()
	end

	return Instance
end

function InlineControls.CreateBoolean(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value
	if CurrentValue == nil then
		CurrentValue = Config.PropertyDef.Default or false
	end
	local IsDisabled = Config.Disabled or false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Checkbox = Instance.new("TextButton")
	Checkbox.Name = "Checkbox"
	Checkbox.Size = UDim2.fromOffset(CHECKBOX_SIZE, CHECKBOX_SIZE)
	Checkbox.Position = UDim2.new(0, 0, 0.5, -CHECKBOX_SIZE / 2)
	Checkbox.BackgroundColor3 = if CurrentValue then Theme.Colors.Primary else Theme.Colors.BackgroundDark
	Checkbox.BorderSizePixel = 0
	Checkbox.Text = ""
	Checkbox.ZIndex = CurrentZIndex + 1
	Checkbox.Parent = Container

	Theme.ApplyCorner(Checkbox, UDim.new(0, 3))
	local CheckboxStroke = Theme.ApplyStroke(Checkbox, Theme.Colors.Border, 1)

	local Checkmark = Instance.new("TextLabel")
	Checkmark.Name = "Checkmark"
	Checkmark.Size = UDim2.fromScale(1, 1)
	Checkmark.BackgroundTransparency = 1
	Checkmark.Text = "✓"
	Checkmark.TextColor3 = Theme.Colors.Text
	Checkmark.FontFace = Theme.Fonts.Bold
	Checkmark.TextSize = 10
	Checkmark.Visible = CurrentValue == true
	Checkmark.ZIndex = CurrentZIndex + 2
	Checkmark.Parent = Checkbox

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(1, -CHECKBOX_SIZE - 6, 1, 0)
	Label.Position = UDim2.fromOffset(CHECKBOX_SIZE + 6, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Config.PropertyDef.Label
	Label.TextColor3 = Theme.Colors.Text
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextTruncate = Enum.TextTruncate.AtEnd
	Label.ZIndex = CurrentZIndex + 1
	Label.Parent = Container

	local function UpdateDisplay()
		Checkbox.BackgroundColor3 = if CurrentValue then Theme.Colors.Primary else Theme.Colors.BackgroundDark
		Checkmark.Visible = CurrentValue == true
	end

	table.insert(Connections, Checkbox.MouseButton1Click:Connect(function()
		if IsDisabled then
			return
		end
		CurrentValue = not CurrentValue
		UpdateDisplay()
		Config.OnChanged(CurrentValue)
	end))

	local Instance: ControlInstance = {
		Frame = Container,
	} :: any

	function Instance.GetValue(): any
		return CurrentValue
	end

	function Instance.SetValue(Value: any)
		CurrentValue = Value == true
		UpdateDisplay()
	end

	function Instance.SetDisabled(Disabled: boolean)
		IsDisabled = Disabled
		Checkbox.AutoButtonColor = not Disabled
		Checkbox.BackgroundTransparency = if Disabled then 0.5 else 0
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
	end

	function Instance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Checkbox.ZIndex = ZIndex + 1
		Checkmark.ZIndex = ZIndex + 2
		Label.ZIndex = ZIndex + 1
	end

	function Instance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

function InlineControls.CreateDropdown(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or ""
	local Options = Config.PropertyDef.Options or {}
	local IsDisabled = Config.Disabled or false
	local IsOpen = false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(0.45, 0, 1, 0)
	Label.Position = UDim2.fromScale(0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Config.PropertyDef.Label
	Label.TextColor3 = Theme.Colors.TextMuted
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextTruncate = Enum.TextTruncate.AtEnd
	Label.ZIndex = CurrentZIndex + 1
	Label.Parent = Container

	local ButtonBackground = Instance.new("Frame")
	ButtonBackground.Name = "ButtonBg"
	ButtonBackground.Size = UDim2.new(0.53, 0, 1, 0)
	ButtonBackground.Position = UDim2.new(0.47, 0, 0, 0)
	ButtonBackground.BackgroundColor3 = Theme.Colors.BackgroundDark
	ButtonBackground.BorderSizePixel = 0
	ButtonBackground.ZIndex = CurrentZIndex
	ButtonBackground.Parent = Container

	Theme.ApplyCorner(ButtonBackground, UDim.new(0, 3))

	local Button = Instance.new("TextButton")
	Button.Name = "DropdownButton"
	Button.Size = UDim2.new(1, -14, 1, 0)
	Button.Position = UDim2.fromOffset(4, 0)
	Button.BackgroundTransparency = 1
	Button.Text = tostring(CurrentValue)
	Button.TextColor3 = Theme.Colors.Text
	Button.FontFace = Theme.Fonts.Default
	Button.TextSize = Theme.TextSizes.Small
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.TextTruncate = Enum.TextTruncate.AtEnd
	Button.ZIndex = CurrentZIndex + 2
	Button.Parent = ButtonBackground

	local Arrow = Instance.new("TextLabel")
	Arrow.Name = "Arrow"
	Arrow.Size = UDim2.fromOffset(12, CONTROL_HEIGHT)
	Arrow.Position = UDim2.new(1, -12, 0, 0)
	Arrow.BackgroundTransparency = 1
	Arrow.Text = "▼"
	Arrow.TextColor3 = Theme.Colors.TextMuted
	Arrow.FontFace = Theme.Fonts.Default
	Arrow.TextSize = 8
	Arrow.ZIndex = CurrentZIndex + 2
	Arrow.Parent = ButtonBackground

	local DropdownList: Frame? = nil

	local function CloseDropdown()
		if DropdownList then
			DropdownList:Destroy()
			DropdownList = nil
		end
		IsOpen = false
	end

	local function OpenDropdown()
		if IsOpen then
			CloseDropdown()
			return
		end

		IsOpen = true

		local ButtonAbsPos = ButtonBackground.AbsolutePosition
		local ButtonAbsSize = ButtonBackground.AbsoluteSize
		local ScreenGui = ButtonBackground:FindFirstAncestorOfClass("ScreenGui")

		DropdownList = Instance.new("Frame")
		DropdownList.Name = "DropdownList"
		DropdownList.Size = UDim2.fromOffset(ButtonAbsSize.X, #Options * (CONTROL_HEIGHT + 2))
		DropdownList.Position = UDim2.fromOffset(ButtonAbsPos.X, ButtonAbsPos.Y + ButtonAbsSize.Y + 2)
		DropdownList.BackgroundColor3 = Theme.Colors.Surface
		DropdownList.BorderSizePixel = 0
		DropdownList.ZIndex = Theme.ZIndex.Dropdown
		DropdownList.Parent = if ScreenGui then ScreenGui else ButtonBackground

		Theme.ApplyCorner(DropdownList, UDim.new(0, 3))
		Theme.ApplyStroke(DropdownList, Theme.Colors.Border, 1)

		local Layout = Instance.new("UIListLayout")
		Layout.FillDirection = Enum.FillDirection.Vertical
		Layout.Padding = UDim.new(0, 2)
		Layout.Parent = DropdownList

		for Index, Option in Options do
			local OptionButton = Instance.new("TextButton")
			OptionButton.Name = "Option_" .. Index
			OptionButton.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
			OptionButton.BackgroundColor3 = Theme.Colors.Surface
			OptionButton.BackgroundTransparency = if Option == CurrentValue then 0.5 else 1
			OptionButton.Text = tostring(Option)
			OptionButton.TextColor3 = Theme.Colors.Text
			OptionButton.FontFace = Theme.Fonts.Default
			OptionButton.TextSize = Theme.TextSizes.Small
			OptionButton.ZIndex = Theme.ZIndex.Dropdown + 1
			OptionButton.Parent = DropdownList

			OptionButton.MouseEnter:Connect(function()
				OptionButton.BackgroundTransparency = 0.5
			end)

			OptionButton.MouseLeave:Connect(function()
				OptionButton.BackgroundTransparency = if Option == CurrentValue then 0.5 else 1
			end)

			OptionButton.MouseButton1Click:Connect(function()
				CurrentValue = Option
				Button.Text = tostring(CurrentValue)
				Config.OnChanged(CurrentValue)
				CloseDropdown()
			end)
		end
	end

	table.insert(Connections, Button.MouseButton1Click:Connect(function()
		if IsDisabled then
			return
		end
		OpenDropdown()
	end))

	table.insert(Connections, UserInputService.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 and IsOpen then
			task.defer(function()
				local MousePos = UserInputService:GetMouseLocation()
				if DropdownList then
					local ListPos = DropdownList.AbsolutePosition
					local ListSize = DropdownList.AbsoluteSize
					local IsInside = MousePos.X >= ListPos.X and MousePos.X <= ListPos.X + ListSize.X
						and MousePos.Y >= ListPos.Y and MousePos.Y <= ListPos.Y + ListSize.Y

					local BgPos = ButtonBackground.AbsolutePosition
					local BgSize = ButtonBackground.AbsoluteSize
					local IsInBg = MousePos.X >= BgPos.X and MousePos.X <= BgPos.X + BgSize.X
						and MousePos.Y >= BgPos.Y and MousePos.Y <= BgPos.Y + BgSize.Y

					if not IsInside and not IsInBg then
						CloseDropdown()
					end
				end
			end)
		end
	end))

	local Instance: ControlInstance = {
		Frame = Container,
	} :: any

	function Instance.GetValue(): any
		return CurrentValue
	end

	function Instance.SetValue(Value: any)
		CurrentValue = Value or ""
		Button.Text = tostring(CurrentValue)
	end

	function Instance.SetDisabled(Disabled: boolean)
		IsDisabled = Disabled
		Button.AutoButtonColor = not Disabled
		ButtonBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		Button.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
		if Disabled then
			CloseDropdown()
		end
	end

	function Instance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Label.ZIndex = ZIndex + 1
		ButtonBackground.ZIndex = ZIndex
		Button.ZIndex = ZIndex + 2
		Arrow.ZIndex = ZIndex + 2
	end

	function Instance.Destroy()
		CloseDropdown()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

function InlineControls.CreateString(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or ""
	local IsDisabled = Config.Disabled or false
	local IsFocused = false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.new(0.45, 0, 1, 0)
	Label.Position = UDim2.fromScale(0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = Config.PropertyDef.Label
	Label.TextColor3 = Theme.Colors.TextMuted
	Label.FontFace = Theme.Fonts.Default
	Label.TextSize = Theme.TextSizes.Small
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextTruncate = Enum.TextTruncate.AtEnd
	Label.ZIndex = CurrentZIndex + 1
	Label.Parent = Container

	local ValueBackground = Instance.new("Frame")
	ValueBackground.Name = "ValueBg"
	ValueBackground.Size = UDim2.new(0.53, 0, 1, 0)
	ValueBackground.Position = UDim2.new(0.47, 0, 0, 0)
	ValueBackground.BackgroundColor3 = Theme.Colors.BackgroundDark
	ValueBackground.BorderSizePixel = 0
	ValueBackground.ZIndex = CurrentZIndex
	ValueBackground.Parent = Container

	Theme.ApplyCorner(ValueBackground, UDim.new(0, 3))

	local TextBox = Instance.new("TextBox")
	TextBox.Name = "Input"
	TextBox.Size = UDim2.new(1, -CONTROL_PADDING * 2, 1, 0)
	TextBox.Position = UDim2.fromOffset(CONTROL_PADDING, 0)
	TextBox.BackgroundTransparency = 1
	TextBox.Text = tostring(CurrentValue)
	TextBox.TextColor3 = Theme.Colors.Text
	TextBox.PlaceholderText = ""
	TextBox.PlaceholderColor3 = Theme.Colors.TextMuted
	TextBox.FontFace = Theme.Fonts.Default
	TextBox.TextSize = Theme.TextSizes.Small
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.TextTruncate = Enum.TextTruncate.AtEnd
	TextBox.ClearTextOnFocus = false
	TextBox.ZIndex = CurrentZIndex + 2
	TextBox.Parent = ValueBackground

	local function SetFocusedLayout(Focused: boolean)
		IsFocused = Focused
		if Focused then
			Label.Visible = false
			ValueBackground.Size = UDim2.new(1, 0, 1, 0)
			ValueBackground.Position = UDim2.fromScale(0, 0)
		else
			Label.Visible = true
			ValueBackground.Size = UDim2.new(0.53, 0, 1, 0)
			ValueBackground.Position = UDim2.new(0.47, 0, 0, 0)
		end
	end

	table.insert(Connections, TextBox.Focused:Connect(function()
		if not IsDisabled then
			SetFocusedLayout(true)
		end
	end))

	table.insert(Connections, TextBox.FocusLost:Connect(function()
		CurrentValue = TextBox.Text
		Config.OnChanged(CurrentValue)
		SetFocusedLayout(false)
	end))

	local Instance: ControlInstance = {
		Frame = Container,
	} :: any

	function Instance.GetValue(): any
		return CurrentValue
	end

	function Instance.SetValue(Value: any)
		CurrentValue = tostring(Value or "")
		TextBox.Text = CurrentValue
	end

	function Instance.SetDisabled(Disabled: boolean)
		IsDisabled = Disabled
		TextBox.TextEditable = not Disabled
		ValueBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		TextBox.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
	end

	function Instance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
	Label.ZIndex = ZIndex + 1
		ValueBackground.ZIndex = ZIndex
		TextBox.ZIndex = ZIndex + 2
	end

	function Instance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

function InlineControls.Create(Config: ControlConfig): ControlInstance?
	local PropType = Config.PropertyDef.Type

	if PropType == "Number" then
		return InlineControls.CreateNumber(Config)
	elseif PropType == "Boolean" then
		return InlineControls.CreateBoolean(Config)
	elseif PropType == "Dropdown" then
		return InlineControls.CreateDropdown(Config)
	elseif PropType == "String" or PropType == "AssetId" then
		return InlineControls.CreateString(Config)
	end

	return nil
end

return InlineControls