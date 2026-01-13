--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local Button = require(script.Parent.Parent.Components.Button)
local TextInput = require(script.Parent.Parent.Components.TextInput)

local Toolbar = {}

export type ToolbarConfig = {
	Parent: Instance?,
	OnSave: (() -> ())?,
	OnLoad: (() -> ())?,
	OnTest: (() -> ())?,
	OnNew: (() -> ())?,
	OnTemplates: (() -> ())?,
	OnExportJson: (() -> ())?,
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
	local Container = UILibrary.ToolbarContainer({
		Name = "Toolbar",
		Size = UDim2.new(1, 0, 0, Theme.Sizes.ToolbarHeight),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})

	local LeftSection = UILibrary.TransparentContainer({
		Name = "Left",
		Size = UDim2.fromScale(0.4, 1),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Container,
	})

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = LeftSection,
	})

	UILibrary.Padding({
		Left = UDim.new(0, 8),
		Parent = LeftSection,
	})

	local RightSection = UILibrary.TransparentContainer({
		Name = "Right",
		Size = UDim2.fromScale(0.6, 1),
		Position = UDim2.fromScale(0.4, 0),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Container,
	})

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = RightSection,
	})

	UILibrary.Padding({
		Right = UDim.new(0, 8),
		Parent = RightSection,
	})

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

	local DirtyIndicator = UILibrary.HeaderLabel({
		Name = "DirtyIndicator",
		Text = "",
		Size = UDim2.fromOffset(16, 28),
		ZIndex = Theme.ZIndex.Panel,
		Parent = LeftSection,
	})
	DirtyIndicator.TextColor3 = Theme.Colors.Warning
	DirtyIndicator.LayoutOrder = 2

	local NewButton = Button.Create({
		Name = "New",
		Text = "New",
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnNew,
	})
	NewButton.Frame.LayoutOrder = 1

	local LoadButton = Button.Create({
		Name = "Load",
		Text = "Load",
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnLoad,
	})
	LoadButton.Frame.LayoutOrder = 3

	local SaveButton = Button.Create({
		Name = "Save",
		Text = "Save",
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor = Theme.Colors.Primary,
		Parent = RightSection,
		OnClick = Config.OnSave,
	})
	SaveButton.Frame.LayoutOrder = 4

	local ExportButton = Button.Create({
		Name = "Export",
		Text = "Export JSON",
		Size = UDim2.fromOffset(90, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnExportJson,
	})
	ExportButton.Frame.LayoutOrder = 5

	local TestButton = Button.Create({
		Name = "Test",
		Text = "Test",
		Size = UDim2.fromOffset(60, 28),
		BackgroundColor = Theme.Colors.Success,
		Parent = RightSection,
		OnClick = Config.OnTest,
	})
	TestButton.Frame.LayoutOrder = 6

	local TemplatesButton = Button.Create({
		Name = "Templates",
		Text = "Templates",
		Size = UDim2.fromOffset(80, 28),
		BackgroundColor = Theme.Colors.Surface,
		Parent = RightSection,
		OnClick = Config.OnTemplates,
	})
	TemplatesButton.Frame.LayoutOrder = 7

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
		TemplatesButton.Destroy()
		LoadButton.Destroy()
		SaveButton.Destroy()
		ExportButton.Destroy()
		TestButton.Destroy()
		Container:Destroy()
	end

	return ToolbarObj
end

return Toolbar