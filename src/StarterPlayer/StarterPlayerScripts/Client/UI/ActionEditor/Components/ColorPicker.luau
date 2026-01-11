--!strict

local Theme = require(script.Parent.Parent.Theme)

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
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "ColorPicker"
	Container.Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = Config.LayoutOrder or 0
	Container.ClipsDescendants = false
	Container.ZIndex = BaseZIndex

	local Button = Instance.new("TextButton")
	Button.Name = "ColorButton"
	Button.Size = UDim2.fromScale(1, 1)
	Button.BackgroundColor3 = CurrentColor
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.ZIndex = BaseZIndex
	Button.Parent = Container

	Theme.ApplyCorner(Button, Theme.Sizes.BorderRadiusSmall)
	Theme.ApplyStroke(Button, Theme.Colors.Border)

	local Dropdown = Instance.new("Frame")
	Dropdown.Name = "Dropdown"
	Dropdown.Size = UDim2.fromOffset(200, 80)
	Dropdown.Position = UDim2.new(0, 0, 1, 4)
	Dropdown.BackgroundColor3 = Theme.Colors.Surface
	Dropdown.BorderSizePixel = 0
	Dropdown.Visible = false
	Dropdown.ZIndex = BaseZIndex + 100
	Dropdown.Parent = Container

	Theme.ApplyCorner(Dropdown, Theme.Sizes.BorderRadiusSmall)
	Theme.ApplyStroke(Dropdown, Theme.Colors.Border)

	local GridLayout = Instance.new("UIGridLayout")
	GridLayout.CellSize = UDim2.fromOffset(32, 32)
	GridLayout.CellPadding = UDim2.fromOffset(4, 4)
	GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	GridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	GridLayout.Parent = Dropdown

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 8)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Dropdown

	local ColorButtons: { TextButton } = {}

	for Index, PresetColor in PRESET_COLORS do
		local ColorButton = Instance.new("TextButton")
		ColorButton.Name = "Color_" .. Index
		ColorButton.Size = UDim2.fromOffset(32, 32)
		ColorButton.BackgroundColor3 = PresetColor
		ColorButton.BorderSizePixel = 0
		ColorButton.Text = ""
		ColorButton.AutoButtonColor = false
		ColorButton.ZIndex = BaseZIndex + 101
		ColorButton.Parent = Dropdown

		Theme.ApplyCorner(ColorButton, Theme.Sizes.BorderRadiusSmall)

		local ColorStroke = Theme.ApplyStroke(ColorButton, Theme.Colors.Border)

		ColorButton.MouseEnter:Connect(function()
			ColorStroke.Color = Theme.Colors.Primary
			ColorStroke.Thickness = Theme.StrokeSizes.Selected
		end)

		ColorButton.MouseLeave:Connect(function()
			ColorStroke.Color = Theme.Colors.Border
			ColorStroke.Thickness = Theme.StrokeSizes.Deslected
		end)

		ColorButton.MouseButton1Click:Connect(function()
			CurrentColor = PresetColor
			Button.BackgroundColor3 = CurrentColor
			Dropdown.Visible = false
			IsOpen = false

			if Config.OnChanged then
				Config.OnChanged(CurrentColor)
			end
		end)

		table.insert(ColorButtons, ColorButton)
	end

	Button.MouseButton1Click:Connect(function()
		IsOpen = not IsOpen
		Dropdown.Visible = IsOpen
	end)

	Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = Color3.new(
			math.min(1, CurrentColor.R + 0.1),
			math.min(1, CurrentColor.G + 0.1),
			math.min(1, CurrentColor.B + 0.1)
		)
	end)

	Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = CurrentColor
	end)

	if Config.Parent then
		Container.Parent = Config.Parent
	end

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
		for _, ColorButton in ColorButtons do
			ColorButton:Destroy()
		end
		table.clear(ColorButtons)
		Container:Destroy()
	end

	return PickerInstance
end

return ColorPicker