--!strict

local DropdownState = require(script.Parent.Parent.State.DropdownState)
local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local InlineControls = {}

local CONTROL_HEIGHT = 18
local CONTROL_PADDING = 4
local CHECKBOX_SIZE = 14
local DROPDOWN_ZINDEX = 10000

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
	local _IsDisabled = Config.Disabled or false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.fromScale(0.45, 1)
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
	ValueBackground.Size = UDim2.fromScale(0.53, 1)
	ValueBackground.Position = UDim2.fromScale(0.47, 0)
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
	TextBox.PlaceholderText = "0"
	TextBox.PlaceholderColor3 = Theme.Colors.TextMuted
	TextBox.FontFace = Theme.Fonts.Default
	TextBox.TextSize = Theme.TextSizes.Small
	TextBox.TextXAlignment = Enum.TextXAlignment.Left
	TextBox.ClearTextOnFocus = false
	TextBox.ZIndex = CurrentZIndex + 2
	TextBox.Parent = ValueBackground

	table.insert(Connections, TextBox.FocusLost:Connect(function()
		local Parsed = tonumber(TextBox.Text)
		if Parsed then
			CurrentValue = Parsed
			Config.OnChanged(CurrentValue)
		else
			TextBox.Text = tostring(CurrentValue)
		end
	end))

	local ControlInstance: ControlInstance = {
		Frame = Container,
	} :: any

	function ControlInstance.GetValue(): any
		return CurrentValue
	end

	function ControlInstance.SetValue(Value: any)
		CurrentValue = tonumber(Value) or 0
		TextBox.Text = tostring(CurrentValue)
	end

	function ControlInstance.SetDisabled(Disabled: boolean)
		_IsDisabled = Disabled
		TextBox.TextEditable = not Disabled
		ValueBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		TextBox.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
	end

	function ControlInstance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Label.ZIndex = ZIndex + 1
		ValueBackground.ZIndex = ZIndex
		TextBox.ZIndex = ZIndex + 2
	end

	function ControlInstance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return ControlInstance
end

function InlineControls.CreateBoolean(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or false
	local _IsDisabled = Config.Disabled or false
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
	Checkbox.AutoButtonColor = true
	Checkbox.ZIndex = CurrentZIndex + 1
	Checkbox.Parent = Container

	Theme.ApplyCorner(Checkbox, UDim.new(0, 3))
	Theme.ApplyStroke(Checkbox, Theme.Colors.Border)

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
	Label.Size = UDim2.new(1, -(CHECKBOX_SIZE + 8), 1, 0)
	Label.Position = UDim2.fromOffset(CHECKBOX_SIZE + 8, 0)
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
		if _IsDisabled then
			return
		end
		CurrentValue = not CurrentValue
		UpdateDisplay()
		Config.OnChanged(CurrentValue)
	end))

	local ControlInstance: ControlInstance = {
		Frame = Container,
	} :: any

	function ControlInstance.GetValue(): any
		return CurrentValue
	end

	function ControlInstance.SetValue(Value: any)
		CurrentValue = Value == true
		UpdateDisplay()
	end

	function ControlInstance.SetDisabled(Disabled: boolean)
		_IsDisabled = Disabled
		Checkbox.AutoButtonColor = not Disabled
		Checkbox.BackgroundTransparency = if Disabled then 0.5 else 0
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
	end

	function ControlInstance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Checkbox.ZIndex = ZIndex + 1
		Checkmark.ZIndex = ZIndex + 2
		Label.ZIndex = ZIndex + 1
	end

	function ControlInstance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return ControlInstance
end

function InlineControls.CreateDropdown(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or ""
	local Options = Config.PropertyDef.Options or {}
	local _IsDisabled = Config.Disabled or false
	local IsOpen = false
	local CurrentDropdownId: string? = nil
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent
	local DropdownList: Frame? = nil
	local Backdrop: TextButton? = nil

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.fromScale(0.45, 1)
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
	ButtonBackground.Size = UDim2.fromScale(0.53, 1)
	ButtonBackground.Position = UDim2.fromScale(0.47, 0)
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

	local function CloseDropdown()
		if Backdrop then
			Backdrop:Destroy()
			Backdrop = nil
		end
		if DropdownList then
			DropdownList:Destroy()
			DropdownList = nil
		end

		if CurrentDropdownId then
			DropdownState.Close(CurrentDropdownId)
			CurrentDropdownId = nil
		end
		IsOpen = false
		Arrow.Text = "▼"
	end

	local function OpenDropdown()
		if IsOpen then
			CloseDropdown()
			return
		end

		CurrentDropdownId = DropdownState.Open()
		IsOpen = true
		Arrow.Text = "▲"

		local ButtonAbsPos = ButtonBackground.AbsolutePosition
		local ButtonAbsSize = ButtonBackground.AbsoluteSize
		local ScreenGui = ButtonBackground:FindFirstAncestorOfClass("ScreenGui")

		if not ScreenGui then
			CloseDropdown()
			return
		end

		local NewBackdrop = Instance.new("TextButton")
		NewBackdrop.Name = "DropdownBackdrop"
		NewBackdrop.Size = UDim2.fromScale(1, 1)
		NewBackdrop.Position = UDim2.fromScale(0, 0)
		NewBackdrop.BackgroundTransparency = 1
		NewBackdrop.Text = ""
		NewBackdrop.ZIndex = DROPDOWN_ZINDEX - 1
		NewBackdrop.Parent = ScreenGui
		Backdrop = NewBackdrop

		NewBackdrop.MouseButton1Click:Connect(function()
			CloseDropdown()
		end)

		local NewDropdownList = Instance.new("Frame")
		NewDropdownList.Name = "DropdownList"
		NewDropdownList.Size = UDim2.fromOffset(ButtonAbsSize.X, #Options * (CONTROL_HEIGHT + 2) + 4)
		NewDropdownList.Position = UDim2.fromOffset(ButtonAbsPos.X, ButtonAbsPos.Y + ButtonAbsSize.Y + 2)
		NewDropdownList.BackgroundColor3 = Theme.Colors.Surface
		NewDropdownList.BorderSizePixel = 0
		NewDropdownList.ZIndex = DROPDOWN_ZINDEX
		NewDropdownList.Parent = ScreenGui
		DropdownList = NewDropdownList

		Theme.ApplyCorner(NewDropdownList, UDim.new(0, 3))
		Theme.ApplyStroke(NewDropdownList, Theme.Colors.Border, 1)

		local Padding = Instance.new("UIPadding")
		Padding.PaddingTop = UDim.new(0, 2)
		Padding.PaddingBottom = UDim.new(0, 2)
		Padding.Parent = DropdownList

		local Layout = Instance.new("UIListLayout")
		Layout.FillDirection = Enum.FillDirection.Vertical
		Layout.Padding = UDim.new(0, 2)
		Layout.Parent = DropdownList

		for Index, Option in pairs(Options) do
			local OptionButton = Instance.new("TextButton")
			OptionButton.Name = "Option_" .. Index
			OptionButton.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
			OptionButton.BackgroundColor3 = Theme.Colors.Surface
			OptionButton.BackgroundTransparency = if Option == CurrentValue then 0.5 else 1
			OptionButton.Text = tostring(Option)
			OptionButton.TextColor3 = Theme.Colors.Text
			OptionButton.FontFace = Theme.Fonts.Default
			OptionButton.TextSize = Theme.TextSizes.Small
			OptionButton.AutoButtonColor = false
			OptionButton.ZIndex = DROPDOWN_ZINDEX + 1
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
		if _IsDisabled then
			return
		end
		if IsOpen then
			CloseDropdown()
		else
			OpenDropdown()
		end
	end))

	local ControlInstance: ControlInstance = {
		Frame = Container,
	} :: any

	function ControlInstance.GetValue(): any
		return CurrentValue
	end

	function ControlInstance.SetValue(Value: any)
		CurrentValue = Value or ""
		Button.Text = tostring(CurrentValue)
	end

	function ControlInstance.SetDisabled(Disabled: boolean)
		_IsDisabled = Disabled
		Button.AutoButtonColor = not Disabled
		ButtonBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		Button.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
		if Disabled then
			CloseDropdown()
		end
	end

	function ControlInstance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Label.ZIndex = ZIndex + 1
		ButtonBackground.ZIndex = ZIndex
		Button.ZIndex = ZIndex + 2
		Arrow.ZIndex = ZIndex + 2
	end

	function ControlInstance.Destroy()
		CloseDropdown()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return ControlInstance
end

function InlineControls.CreateString(Config: ControlConfig): ControlInstance
	local CurrentValue = Config.Value or Config.PropertyDef.Default or ""
	local _IsDisabled = Config.Disabled or false
	local _IsFocused = false
	local Connections: { RBXScriptConnection } = {}
	local CurrentZIndex = Config.ZIndex or Theme.ZIndex.NodeContent

	local Container = CreateBaseContainer(Config)

	local Label = Instance.new("TextLabel")
	Label.Name = "Label"
	Label.Size = UDim2.fromScale(0.45, 1)
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
	ValueBackground.Size = UDim2.fromScale(0.53, 1)
	ValueBackground.Position = UDim2.fromScale(0.47, 0)
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
		_IsFocused = Focused
		if Focused then
			Label.Visible = false
			ValueBackground.Size = UDim2.fromScale(1, 1)
			ValueBackground.Position = UDim2.fromScale(0, 0)
		else
			Label.Visible = true
			ValueBackground.Size = UDim2.fromScale(0.53, 1)
			ValueBackground.Position = UDim2.fromScale(0.47, 0)
		end
	end

	table.insert(Connections, TextBox.Focused:Connect(function()
		if not _IsDisabled then
			SetFocusedLayout(true)
		end
	end))

	table.insert(Connections, TextBox.FocusLost:Connect(function()
		CurrentValue = TextBox.Text
		Config.OnChanged(CurrentValue)
		SetFocusedLayout(false)
	end))

	local ControlInstance: ControlInstance = {
		Frame = Container,
	} :: any

	function ControlInstance.GetValue(): any
		return CurrentValue
	end

	function ControlInstance.SetValue(Value: any)
		CurrentValue = tostring(Value or "")
		TextBox.Text = CurrentValue
	end

	function ControlInstance.SetDisabled(Disabled: boolean)
		_IsDisabled = Disabled
		TextBox.TextEditable = not Disabled
		ValueBackground.BackgroundTransparency = if Disabled then 0.5 else 0
		TextBox.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.Text
		Label.TextColor3 = if Disabled then Theme.Colors.TextMuted else Theme.Colors.TextMuted
	end

	function ControlInstance.SetZIndex(ZIndex: number)
		CurrentZIndex = ZIndex
		Container.ZIndex = ZIndex
		Label.ZIndex = ZIndex + 1
		ValueBackground.ZIndex = ZIndex
		TextBox.ZIndex = ZIndex + 2
	end

	function ControlInstance.Destroy()
		for _, Conn in Connections do
			Conn:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return ControlInstance
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