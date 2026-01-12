--!strict

local Theme = require(script.Parent.Parent.Theme)
local DropdownState = require(script.Parent.Parent.State.DropdownState)

local Dropdown = {}

export type DropdownConfig = {
	Name: string?,
	Options: { string },
	Selected: string?,
	Placeholder: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: GuiObject?,
	OnSelected: ((Option: string) -> ())?,
}

export type DropdownInstance = {
	Frame: Frame,
	GetSelected: () -> string?,
	SetSelected: (Option: string?) -> (),
	SetOptions: (Options: { string }) -> (),
	Destroy: () -> (),
}

function Dropdown.Create(Config: DropdownConfig): DropdownInstance
	local Options = Config.Options or {}
	local SelectedOption = Config.Selected
	local IsOpen = false
	local CurrentDropdownId: string? = nil
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "Dropdown"
	Container.Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Config.LayoutOrder or 0
	Container.ClipsDescendants = false
	Container.ZIndex = BaseZIndex

	local Button = Instance.new("TextButton")
	Button.Name = "Button"
	Button.Size = UDim2.fromScale(1, 1)
	Button.BackgroundColor3 = Theme.Colors.BackgroundDark
	Button.BorderSizePixel = 0
	Button.Text = SelectedOption or Config.Placeholder or "Select..."
	Button.TextColor3 = if SelectedOption then Theme.Colors.Text else Theme.Colors.TextMuted
	Button.FontFace = Theme.Fonts.Default
	Button.TextSize = Theme.TextSizes.Default
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.AutoButtonColor = false
	Button.ZIndex = BaseZIndex
	Button.Parent = Container

	Theme.ApplyCorner(Button, Theme.Sizes.BorderRadiusSmall)
	Theme.ApplyStroke(Button, Theme.Colors.Border)
	Theme.ApplyPadding(Button, UDim.new(0, 8))

	local Arrow = Instance.new("TextLabel")
	Arrow.Name = "Arrow"
	Arrow.Size = UDim2.fromOffset(16, 16)
	Arrow.Position = UDim2.new(1, -4, 0.5, 0)
	Arrow.AnchorPoint = Vector2.new(1, 0.5)
	Arrow.BackgroundTransparency = 1
	Arrow.Text = "▼"
	Arrow.TextColor3 = Theme.Colors.TextMuted
	Arrow.FontFace = Theme.Fonts.Default
	Arrow.TextSize = 10
	Arrow.ZIndex = BaseZIndex + 1
	Arrow.Parent = Button

	local OptionsList = Instance.new("Frame")
	OptionsList.Name = "Options"
	OptionsList.Size = UDim2.fromScale(1, 0)
	OptionsList.Position = UDim2.new(0, 0, 1, 4)
	OptionsList.BackgroundColor3 = Theme.Colors.Surface
	OptionsList.BorderSizePixel = 0
	OptionsList.Visible = false
	OptionsList.ZIndex = Theme.ZIndex.Dropdown
	OptionsList.AutomaticSize = Enum.AutomaticSize.Y
	OptionsList.Parent = Container

	Theme.ApplyCorner(OptionsList, Theme.Sizes.BorderRadiusSmall)
	Theme.ApplyStroke(OptionsList, Theme.Colors.Border)

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.FillDirection = Enum.FillDirection.Vertical
	ListLayout.Padding = UDim.new(0, 0)
	ListLayout.Parent = OptionsList

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingTop = UDim.new(0, 4)
	ListPadding.PaddingBottom = UDim.new(0, 4)
	ListPadding.Parent = OptionsList

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}
	local OptionButtons: { TextButton } = {}

	local function CloseDropdown()
		if CurrentDropdownId then
			DropdownState.Close(CurrentDropdownId)
			CurrentDropdownId = nil
		end
		IsOpen = false
		OptionsList.Visible = false
		Arrow.Text = "▼"
	end

	local function OpenDropdown()
		CurrentDropdownId = DropdownState.Open()
		IsOpen = true
		OptionsList.Visible = true
		Arrow.Text = "▲"
	end

	local function SelectOption(Option: string)
		SelectedOption = Option
		Button.Text = Option
		Button.TextColor3 = Theme.Colors.Text
		CloseDropdown()
		if Config.OnSelected then
			Config.OnSelected(Option)
		end
	end

	local function RebuildOptions()
		for _, OptionButton in OptionButtons do
			OptionButton:Destroy()
		end
		table.clear(OptionButtons)

		local Iterator = 0
		for Index, Option in pairs(Options) do
			Iterator += 1
			local OptionButton = Instance.new("TextButton")
			OptionButton.Name = "Option_" .. Index
			OptionButton.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
			OptionButton.BackgroundColor3 = Theme.Colors.Surface
			OptionButton.BackgroundTransparency = 1
			OptionButton.BorderSizePixel = 0
			OptionButton.Text = Option
			OptionButton.TextColor3 = Theme.Colors.Text
			OptionButton.FontFace = Theme.Fonts.Default
			OptionButton.TextSize = Theme.TextSizes.Default
			OptionButton.TextXAlignment = Enum.TextXAlignment.Left
			OptionButton.AutoButtonColor = false
			OptionButton.ZIndex = Theme.ZIndex.Dropdown + 1
			OptionButton.LayoutOrder = Iterator
			OptionButton.Parent = OptionsList

			local OptionPadding = Instance.new("UIPadding")
			OptionPadding.PaddingLeft = UDim.new(0, 8)
			OptionPadding.Parent = OptionButton

			OptionButton.MouseEnter:Connect(function()
				OptionButton.BackgroundTransparency = 0
				OptionButton.BackgroundColor3 = Theme.Colors.SurfaceHover
			end)

			OptionButton.MouseLeave:Connect(function()
				OptionButton.BackgroundTransparency = 1
			end)

			OptionButton.MouseButton1Click:Connect(function()
				SelectOption(Option)
			end)

			table.insert(OptionButtons, OptionButton)
		end
	end

	table.insert(Connections, Button.MouseButton1Click:Connect(function()
		if IsOpen then
			CloseDropdown()
		else
			OpenDropdown()
		end
	end))

	table.insert(Connections, Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = Theme.Colors.SurfaceHover
	end))

	table.insert(Connections, Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = Theme.Colors.BackgroundDark
	end))

	RebuildOptions()

	local DropdownInstance: DropdownInstance = {
		Frame = Container,
	} :: any

	function DropdownInstance.GetSelected(): string?
		return SelectedOption
	end

	function DropdownInstance.SetSelected(Option: string?)
		SelectedOption = Option
		if Option then
			Button.Text = Option
			Button.TextColor3 = Theme.Colors.Text
		else
			Button.Text = Config.Placeholder or "Select..."
			Button.TextColor3 = Theme.Colors.TextMuted
		end
	end

	function DropdownInstance.SetOptions(NewOptions: { string })
		Options = NewOptions
		RebuildOptions()
	end

	function DropdownInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		CloseDropdown()
		table.clear(Connections)
		table.clear(OptionButtons)
		Container:Destroy()
	end

	return DropdownInstance
end

return Dropdown