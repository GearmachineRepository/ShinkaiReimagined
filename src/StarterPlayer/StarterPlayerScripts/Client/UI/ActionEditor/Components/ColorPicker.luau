--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local DropdownState = require(script.Parent.Parent.State.DropdownState)

local ColorPicker = {}

export type ColorPickerConfig = {
	Name: string?,
	Color: Color3?,
	Size: UDim2?,
	Position: UDim2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: GuiObject?,
	OnChanged: ((Color: Color3) -> ())?,
}

export type ColorPickerInstance = {
	Frame: Frame,
	GetColor: () -> Color3,
	SetColor: (Color: Color3) -> (),
	Destroy: () -> (),
}

local PRESET_COLORS = {
	Color3.fromRGB(50, 50, 55),
	Color3.fromRGB(70, 50, 50),
	Color3.fromRGB(50, 70, 50),
	Color3.fromRGB(50, 50, 70),
	Color3.fromRGB(70, 70, 50),
	Color3.fromRGB(70, 50, 70),
	Color3.fromRGB(50, 70, 70),
	Color3.fromRGB(80, 60, 40),
	Color3.fromRGB(60, 40, 60),
	Color3.fromRGB(40, 60, 60),
}

function ColorPicker.Create(Config: ColorPickerConfig): ColorPickerInstance
	local CurrentColor = Config.Color or Color3.fromRGB(50, 50, 55)
	local IsOpen = false
	local CurrentDropdownId: string? = nil
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel
	local Connections: { RBXScriptConnection } = {}
	local ColorButtons: { TextButton } = {}

	local Container = UILibrary.TransparentContainer({
		Name = Config.Name or "ColorPicker",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		LayoutOrder = Config.LayoutOrder,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	local Button = UILibrary.ColorSwatch({
		Color = CurrentColor,
		Size = UDim2.fromScale(1, 1),
		ZIndex = BaseZIndex,
		Parent = Container,
	})
	UILibrary.Stroke(Button, Theme.Colors.Border)

	local Dropdown = UILibrary.ColorPickerDropdown({
		ZIndex = BaseZIndex + 100,
		Parent = Container,
	})

	local function CloseDropdown()
		if CurrentDropdownId then
			DropdownState.Close(CurrentDropdownId)
			CurrentDropdownId = nil
		end
		IsOpen = false
		Dropdown.Visible = false
	end

	local function OpenDropdown()
		CurrentDropdownId = DropdownState.Open()
		IsOpen = true
		Dropdown.Visible = true
	end

	for _, PresetColor in PRESET_COLORS do
		local ColorButton = UILibrary.ColorSwatch({
			Color = PresetColor,
			ZIndex = BaseZIndex + 101,
			Parent = Dropdown,
		})

		local ColorStroke = UILibrary.Stroke(ColorButton, Theme.Colors.Border)

		table.insert(Connections, ColorButton.MouseEnter:Connect(function()
			ColorStroke.Color = Theme.Colors.Primary
			ColorStroke.Thickness = Theme.StrokeSizes.Selected
		end))

		table.insert(Connections, ColorButton.MouseLeave:Connect(function()
			ColorStroke.Color = Theme.Colors.Border
			ColorStroke.Thickness = Theme.StrokeSizes.Deslected
		end))

		table.insert(Connections, ColorButton.MouseButton1Click:Connect(function()
			CurrentColor = PresetColor
			Button.BackgroundColor3 = CurrentColor
			CloseDropdown()
			if Config.OnChanged then
				Config.OnChanged(CurrentColor)
			end
		end))

		table.insert(ColorButtons, ColorButton)
	end

	table.insert(Connections, Button.MouseButton1Click:Connect(function()
		if IsOpen then
			CloseDropdown()
		else
			OpenDropdown()
		end
	end))

	table.insert(Connections, Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = Color3.new(
			math.min(1, CurrentColor.R + 0.1),
			math.min(1, CurrentColor.G + 0.1),
			math.min(1, CurrentColor.B + 0.1)
		)
	end))

	table.insert(Connections, Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = CurrentColor
	end))

	local PickerInstance: ColorPickerInstance = {
		Frame = Container,
	} :: any

	function PickerInstance.GetColor(): Color3
		return CurrentColor
	end

	function PickerInstance.SetColor(Color: Color3)
		CurrentColor = Color
		Button.BackgroundColor3 = Color
	end

	function PickerInstance.Destroy()
		CloseDropdown()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		table.clear(ColorButtons)
		Container:Destroy()
	end

	return PickerInstance
end

return ColorPicker