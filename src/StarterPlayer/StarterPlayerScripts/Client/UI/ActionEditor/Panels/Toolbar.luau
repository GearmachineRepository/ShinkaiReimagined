--!strict

local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Parent.Components.Button)
local TextInput = require(script.Parent.Parent.Components.TextInput)

local Toolbar = {}

export type ToolbarConfig = {
	Parent: GuiObject?,
	OnSave: (() -> ())?,
	OnLoad: (() -> ())?,
	OnTest: (() -> ())?,
	OnNew: (() -> ())?,
	OnNameChanged: ((Name: string) -> ())?,
}

export type ToolbarInstance = {
	Frame: Frame,
	SetActionName: (Name: string) -> (),
	SetDirty: (Dirty: boolean) -> (),
	SetTestEnabled: (Enabled: boolean) -> (),
	Destroy: () -> (),
}

function Toolbar.Create(Config: ToolbarConfig): ToolbarInstance
	local Container = Instance.new("Frame")
	Container.Name = "Toolbar"
	Container.Size = UDim2.new(1, 0, 0, Theme.Sizes.ToolbarHeight)
	Container.BackgroundColor3 = Theme.Colors.BackgroundDark
	Container.BorderSizePixel = 0

	Theme.ApplyStroke(Container, Theme.Colors.Border)

	local LeftSection = Instance.new("Frame")
	LeftSection.Name = "Left"
	LeftSection.Size = UDim2.fromScale(0.5, 1)
	LeftSection.BackgroundTransparency = 1
	LeftSection.Parent = Container

	local LeftLayout = Instance.new("UIListLayout")
	LeftLayout.FillDirection = Enum.FillDirection.Horizontal
	LeftLayout.Padding = UDim.new(0, 8)
	LeftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	LeftLayout.Parent = LeftSection

	local LeftPadding = Instance.new("UIPadding")
	LeftPadding.PaddingLeft = UDim.new(0, 8)
	LeftPadding.Parent = LeftSection

	local RightSection = Instance.new("Frame")
	RightSection.Name = "Right"
	RightSection.Size = UDim2.fromScale(0.5, 1)
	RightSection.Position = UDim2.fromScale(0.5, 0)
	RightSection.BackgroundTransparency = 1
	RightSection.Parent = Container

	local RightLayout = Instance.new("UIListLayout")
	RightLayout.FillDirection = Enum.FillDirection.Horizontal
	RightLayout.Padding = UDim.new(0, 8)
	RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	RightLayout.Parent = RightSection

	local RightPadding = Instance.new("UIPadding")
	RightPadding.PaddingRight = UDim.new(0, 8)
	RightPadding.Parent = RightSection

	local NameInput = TextInput.Create({
		Name = "ActionName",
		Text = "New Action",
		PlaceholderText = "Action Name",
		Size = UDim2.fromOffset(200, 28),
		Parent = LeftSection,
		OnFocusLost = function(Text: string)
			if Config.OnNameChanged then
				Config.OnNameChanged(Text)
			end
		end,
	})
	NameInput.Frame.LayoutOrder = 1

	local DirtyIndicator = Instance.new("TextLabel")
	DirtyIndicator.Name = "DirtyIndicator"
	DirtyIndicator.Size = UDim2.fromOffset(16, 28)
	DirtyIndicator.BackgroundTransparency = 1
	DirtyIndicator.Text = ""
	DirtyIndicator.TextColor3 = Theme.Colors.Warning
	DirtyIndicator.FontFace = Theme.Fonts.Bold
	DirtyIndicator.TextSize = Theme.TextSizes.Large
	DirtyIndicator.LayoutOrder = 2
	DirtyIndicator.Parent = LeftSection

	local NewButton = Button.Create({
		Name = "New",
		Text = "New",
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnNew,
	})
	NewButton.Frame.LayoutOrder = 1

	local LoadButton = Button.Create({
		Name = "Load",
		Text = "Load",
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnLoad,
	})
	LoadButton.Frame.LayoutOrder = 2

	local SaveButton = Button.Create({
		Name = "Save",
		Text = "Save",
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor = Theme.Colors.Primary,
		Parent = RightSection,
		OnClick = Config.OnSave,
	})
	SaveButton.Frame.LayoutOrder = 3

	local TestButton = Button.Create({
		Name = "Test",
		Text = "Test",
		Size = UDim2.fromOffset(70, 28),
		BackgroundColor = Theme.Colors.Success,
		Parent = RightSection,
		OnClick = Config.OnTest,
	})
	TestButton.Frame.LayoutOrder = 4

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local ToolbarObj: ToolbarInstance = {
		Frame = Container,
	} :: any

	function ToolbarObj.SetActionName(Name: string)
		NameInput.SetText(Name)
	end

	function ToolbarObj.SetDirty(Dirty: boolean)
		DirtyIndicator.Text = if Dirty then "*" else ""
	end

	function ToolbarObj.SetTestEnabled(Enabled: boolean)
		TestButton.SetEnabled(Enabled)
	end

	function ToolbarObj.Destroy()
		NameInput.Destroy()
		NewButton.Destroy()
		LoadButton.Destroy()
		SaveButton.Destroy()
		TestButton.Destroy()
		Container:Destroy()
	end

	return ToolbarObj
end

return Toolbar
