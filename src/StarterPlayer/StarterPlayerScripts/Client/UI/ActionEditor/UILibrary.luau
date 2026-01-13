--!strict

local Theme = require(script.Parent.Theme)
local UIFactory = require(script.Parent.UIFactory)

local UILibrary = {}

--[[
	BUTTONS
	Standardized button styles used throughout the editor.
	Change these to update ALL buttons of that type.
]]

export type ButtonConfig = {
	Name: string?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

function UILibrary.PrimaryButton(Config: ButtonConfig): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "PrimaryButton",
		Text = Config.Text or "Button",
		Size = Config.Size or UDim2.fromOffset(80, Theme.Sizes.ButtonHeight),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Primary,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Default,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

function UILibrary.SecondaryButton(Config: ButtonConfig): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "SecondaryButton",
		Text = Config.Text or "Button",
		Size = Config.Size or UDim2.fromOffset(80, Theme.Sizes.ButtonHeight),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})
end

function UILibrary.DangerButton(Config: ButtonConfig): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "DangerButton",
		Text = Config.Text or "Delete",
		Size = Config.Size or UDim2.fromOffset(80, Theme.Sizes.ButtonHeight),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Error,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Default,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

function UILibrary.GhostButton(Config: ButtonConfig): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "GhostButton",
		Text = Config.Text or "Cancel",
		Size = Config.Size or UDim2.fromOffset(80, Theme.Sizes.ButtonHeight),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		BackgroundTransparency = 0.5,
		TextColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

function UILibrary.ToolbarButton(Config: ButtonConfig): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "ToolbarButton",
		Text = Config.Text or "Action",
		Size = Config.Size or UDim2.fromOffset(70, 28),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Small,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

function UILibrary.ListItemButton(Config: ButtonConfig & { ShowColorBar: boolean?, BarColor: Color3? }): TextButton
	local Button = UIFactory.TextButton({
		Name = Config.Name or "ListItem",
		Text = "",
		Size = Config.Size or UDim2.new(1, 0, 0, 28),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})

	if Config.ShowColorBar and Config.BarColor then
		UIFactory.Frame({
			Name = "ColorBar",
			Size = UDim2.new(0, 3, 1, -4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundColor = Config.BarColor,
			ZIndex = (Config.ZIndex or Theme.ZIndex.Panel) + 1,
			Corner = Theme.Sizes.BorderRadiusSmall,
			Parent = Button,
		})
	end

	UIFactory.TextLabel({
		Name = "Label",
		Text = Config.Text or "",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = (Config.ZIndex or Theme.ZIndex.Panel) + 1,
		Parent = Button,
	})

	return Button
end

function UILibrary.IconButton(Config: ButtonConfig & { Icon: string? }): TextButton
	return UIFactory.TextButton({
		Name = Config.Name or "IconButton",
		Text = Config.Icon or Config.Text or "×",
		Size = Config.Size or UDim2.fromOffset(20, 20),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Default,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

--[[
	PANELS & CONTAINERS
	Standardized container styles for consistent layout.
]]

export type PanelConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

function UILibrary.SidePanel(Config: PanelConfig): Frame
	return UIFactory.Frame({
		Name = Config.Name or "SidePanel",
		Size = Config.Size or UDim2.new(0, Theme.Sizes.PanelWidth, 1, 0),
		Position = Config.Position or UDim2.fromScale(0, 0),
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Background,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})
end

function UILibrary.ToolbarContainer(Config: PanelConfig): Frame
	return UIFactory.Frame({
		Name = Config.Name or "Toolbar",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.ToolbarHeight),
		Position = Config.Position or UDim2.fromScale(0, 0),
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.BackgroundDark,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})
end

function UILibrary.SurfaceContainer(Config: PanelConfig): Frame
	return UIFactory.Frame({
		Name = Config.Name or "Container",
		Size = Config.Size or UDim2.fromScale(1, 1),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.Surface,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})
end

function UILibrary.TransparentContainer(Config: PanelConfig): Frame
	return UIFactory.Frame({
		Name = Config.Name or "Container",
		Size = Config.Size or UDim2.fromScale(1, 1),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundTransparency = 1,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

function UILibrary.ScrollContainer(Config: PanelConfig & { AutomaticSize: Enum.AutomaticSize? }): ScrollingFrame
	local Scroll = UIFactory.ScrollingFrame({
		Name = Config.Name or "ScrollContainer",
		Size = Config.Size or UDim2.fromScale(1, 1),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarColor = Theme.Colors.TextMuted,
		AutomaticCanvasSize = Config.AutomaticSize or Enum.AutomaticSize.Y,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})

	UIFactory.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		Parent = Scroll,
	})

	return Scroll
end

function UILibrary.DarkScrollContainer(Config: PanelConfig & { AutomaticSize: Enum.AutomaticSize? }): ScrollingFrame
	local Scroll = UIFactory.ScrollingFrame({
		Name = Config.Name or "ScrollContainer",
		Size = Config.Size or UDim2.fromScale(1, 1),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Theme.Colors.BackgroundDark,
		BackgroundTransparency = 0,
		ScrollBarThickness = 6,
		ScrollBarColor = Theme.Colors.BorderLight,
		AutomaticCanvasSize = Config.AutomaticSize or Enum.AutomaticSize.Y,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})

	UIFactory.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		Parent = Scroll,
	})

	UIFactory.Padding({
		All = UDim.new(0, 4),
		Parent = Scroll,
	})

	return Scroll
end

--[[
	MODALS & OVERLAYS
]]

export type ModalContainerResult = {
	Overlay: TextButton,
	Dialog: Frame,
	Scale: UIScale,
}

function UILibrary.ModalContainer(Config: { Size: UDim2?, ZIndex: number?, Parent: Instance? }): ModalContainerResult
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Modal

	local Overlay = UIFactory.TextButton({
		Name = "ModalOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor = Theme.Colors.Overlay,
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	local Dialog = UIFactory.Frame({
		Name = "ModalDialog",
		Size = Config.Size or UDim2.fromOffset(360, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = Theme.Colors.Surface,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = BaseZIndex + 1,
		Corner = Theme.Sizes.BorderRadiusLarge,
		Stroke = Theme.Colors.Border,
		Parent = Overlay,
	})

	local Scale = UIFactory.Scale(Dialog, 0.9)

	return {
		Overlay = Overlay,
		Dialog = Dialog,
		Scale = Scale,
	}
end

function UILibrary.ModalHeader(Config: { Title: string, ZIndex: number?, Parent: Instance? }): Frame
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Modal + 2

	local Header = UIFactory.Frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor = Theme.Colors.BackgroundDark,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	UIFactory.Corner(Header, Theme.Sizes.BorderRadiusLarge)

	UIFactory.Frame({
		Name = "Mask",
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor = Theme.Colors.BackgroundDark,
		ZIndex = BaseZIndex,
		Parent = Header,
	})

	UIFactory.TextLabel({
		Name = "Title",
		Text = Config.Title,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Large,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = BaseZIndex + 1,
		Parent = Header,
	})

	return Header
end

--[[
	DROPDOWNS
]]

export type DropdownContainerResult = {
	Container: Frame,
	Button: TextButton,
	Arrow: TextLabel,
}

function UILibrary.DropdownButton(Config: {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	Text: string?,
	Placeholder: string?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}): DropdownContainerResult
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = UIFactory.Frame({
		Name = Config.Name or "Dropdown",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		BackgroundTransparency = 1,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	local Button = UIFactory.TextButton({
		Name = "Button",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor = Theme.Colors.BackgroundDark,
		Text = Config.Text or Config.Placeholder or "Select...",
		TextColor = if Config.Text then Theme.Colors.Text else Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = BaseZIndex,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Padding = UDim.new(0, 8),
		Parent = Container,
	})

	local Arrow = UIFactory.TextLabel({
		Name = "Arrow",
		Text = "▼",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Small,
		ZIndex = BaseZIndex + 1,
		Parent = Button,
	})

	return {
		Container = Container,
		Button = Button,
		Arrow = Arrow,
	}
end

function UILibrary.DropdownList(Config: {
	Size: UDim2?,
	Position: UDim2?,
	ZIndex: number?,
	Parent: Instance?,
}): ScrollingFrame
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Dropdown

	local List = UIFactory.ScrollingFrame({
		Name = "DropdownList",
		Size = Config.Size or UDim2.fromOffset(200, 100),
		Position = Config.Position or UDim2.new(0, 0, 1, 2),
		BackgroundColor = Theme.Colors.Surface,
		BackgroundTransparency = 0,
		ScrollBarThickness = 4,
		ScrollBarColor = Theme.Colors.TextMuted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = BaseZIndex,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})

	UILibrary.Stroke(List, Theme.Colors.Border)

	UIFactory.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 2),
		Parent = List,
	})

	UIFactory.Padding({
		Top = UDim.new(0, 2),
		Bottom = UDim.new(0, 2),
		Parent = List,
	})

	return List
end

function UILibrary.DropdownOption(Config: {
	Text: string,
	Selected: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}): TextButton
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Dropdown + 1

	return UIFactory.TextButton({
		Name = "Option",
		Text = Config.Text,
		Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		BackgroundColor = Theme.Colors.Surface,
		BackgroundTransparency = if Config.Selected then 0.5 else 1,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Padding = UDim.new(0, 8),
		Parent = Config.Parent,
	})
end

function UILibrary.DropdownBackdrop(Config: { ZIndex: number?, Parent: Instance? }): TextButton
	return UIFactory.TextButton({
		Name = "DropdownBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = (Config.ZIndex or Theme.ZIndex.Dropdown) - 1,
		Parent = Config.Parent,
	})
end

--[[
	INPUTS
]]

export type InputConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	Text: string?,
	PlaceholderText: string?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

function UILibrary.TextInput(Config: InputConfig): TextBox
	return UIFactory.TextBox({
		Name = Config.Name or "TextInput",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		BackgroundColor = Theme.Colors.BackgroundDark,
		Text = Config.Text or "",
		PlaceholderText = Config.PlaceholderText or "",
		TextColor = Theme.Colors.Text,
		PlaceholderColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Padding = UDim.new(0, 8),
		Parent = Config.Parent,
	})
end

function UILibrary.MultilineInput(Config: InputConfig & { Height: number? }): TextBox
	return UIFactory.TextBox({
		Name = Config.Name or "MultilineInput",
		Size = Config.Size or UDim2.new(1, 0, 0, Config.Height or 80),
		Position = Config.Position,
		BackgroundColor = Theme.Colors.BackgroundDark,
		Text = Config.Text or "",
		PlaceholderText = Config.PlaceholderText or "",
		TextColor = Theme.Colors.Text,
		PlaceholderColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		MultiLine = true,
		TextWrapped = true,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Padding = UDim.new(0, 8),
		Parent = Config.Parent,
	})
end

function UILibrary.NumberInput(Config: InputConfig): TextBox
	return UIFactory.TextBox({
		Name = Config.Name or "NumberInput",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		BackgroundColor = Theme.Colors.BackgroundDark,
		Text = Config.Text or "0",
		PlaceholderText = Config.PlaceholderText or "0",
		TextColor = Theme.Colors.Text,
		PlaceholderColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

--[[
	LABELS
]]

export type LabelConfig = {
	Name: string?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

function UILibrary.HeaderLabel(Config: LabelConfig): TextLabel
	return UIFactory.TextLabel({
		Name = Config.Name or "Header",
		Text = Config.Text or "Header",
		Size = Config.Size or UDim2.new(1, 0, 0, 24),
		Position = Config.Position,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Large,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

function UILibrary.SectionLabel(Config: LabelConfig): TextLabel
	return UIFactory.TextLabel({
		Name = Config.Name or "Section",
		Text = Config.Text or "Section",
		Size = Config.Size or UDim2.new(1, 0, 0, 20),
		Position = Config.Position,
		TextColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Small,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

function UILibrary.PropertyLabel(Config: LabelConfig): TextLabel
	return UIFactory.TextLabel({
		Name = Config.Name or "PropertyLabel",
		Text = Config.Text or "Property",
		Size = Config.Size or UDim2.new(1, 0, 0, 18),
		Position = Config.Position,
		TextColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Small,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

function UILibrary.BodyLabel(Config: LabelConfig): TextLabel
	return UIFactory.TextLabel({
		Name = Config.Name or "Body",
		Text = Config.Text or "",
		Size = Config.Size or UDim2.fromScale(1, 0),
		Position = Config.Position,
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

--[[
	PROPERTY ROWS
	Common pattern: Label on top, input below
]]

export type PropertyRowResult = {
	Container: Frame,
	Label: TextLabel,
	InputContainer: Frame,
}

function UILibrary.PropertyRow(Config: {
	Name: string?,
	Label: string,
	InputHeight: number?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}): PropertyRowResult
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel
	local InputHeight = Config.InputHeight or Theme.Sizes.InputHeight

	local Container = UIFactory.Frame({
		Name = Config.Name or "Property_" .. Config.Label,
		Size = UDim2.new(1, 0, 0, InputHeight + 24),
		BackgroundTransparency = 1,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	local Label = UIFactory.TextLabel({
		Name = "Label",
		Text = Config.Label,
		Size = UDim2.new(1, 0, 0, 18),
		TextColor = Theme.Colors.TextMuted,
		Font = Theme.Fonts.Default,
		TextSize = Theme.TextSizes.Small,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = BaseZIndex,
		Parent = Container,
	})

	local InputContainer = UIFactory.Frame({
		Name = "InputContainer",
		Size = UDim2.new(1, 0, 0, InputHeight),
		Position = UDim2.fromOffset(0, 20),
		BackgroundTransparency = 1,
		ZIndex = BaseZIndex,
		Parent = Container,
	})

	return {
		Container = Container,
		Label = Label,
		InputContainer = InputContainer,
	}
end

--[[
	NODE COMPONENTS
	Specific to the node graph editor
]]

function UILibrary.NodeContainer(Config: {
	NodeId: string,
	Size: UDim2,
	Position: UDim2?,
	ZIndex: number?,
	Parent: Instance?,
}): Frame
	return UIFactory.Frame({
		Name = "Node_" .. Config.NodeId,
		Size = Config.Size,
		Position = Config.Position or UDim2.fromOffset(0, 0),
		BackgroundColor = Theme.Colors.Surface,
		ZIndex = Config.ZIndex or Theme.ZIndex.Node,
		Active = true,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		StrokeThickness = Theme.StrokeSizes.Deslected,
		Parent = Config.Parent,
	})
end

function UILibrary.NodeHeader(Config: {
	Color: Color3,
	ZIndex: number?,
	Parent: Instance?,
}): Frame
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.NodeHeader

	local Header = UIFactory.Frame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Theme.Sizes.NodeHeaderHeight),
		BackgroundColor = Config.Color,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	UIFactory.Corner(Header, Theme.Sizes.BorderRadiusSmall)

	UIFactory.Frame({
		Name = "Mask",
		Size = UDim2.new(1, 0, 0, 8),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor = Config.Color,
		ZIndex = BaseZIndex,
		Parent = Header,
	})

	return Header
end

function UILibrary.NodeTitle(Config: {
	Text: string,
	ZIndex: number?,
	Parent: Instance?,
}): TextLabel
	return UIFactory.TextLabel({
		Name = "Title",
		Text = Config.Text,
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = Theme.TextSizes.Default,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = Config.ZIndex or Theme.ZIndex.NodeHeader + 1,
		Parent = Config.Parent,
	})
end

function UILibrary.PortCircle(Config: {
	Color: Color3,
	Size: number?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	ZIndex: number?,
	Parent: Instance?,
}): Frame
	local Size = Config.Size or (Theme.Sizes.NodePortRadius * 2)
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Port

	local Circle = UIFactory.Frame({
		Name = "Circle",
		Size = UDim2.fromOffset(Size, Size),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = Config.Color,
		ZIndex = BaseZIndex,
		Corner = UDim.new(0.5, 0),
		Parent = Config.Parent,
	})

	UIFactory.Frame({
		Name = "InnerCircle",
		Size = UDim2.fromScale(0.55, 0.55),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor = Color3.new(
			Config.Color.R * 0.85,
			Config.Color.G * 0.85,
			Config.Color.B * 0.85
		),
		ZIndex = BaseZIndex + 1,
		Corner = UDim.new(0.5, 0),
		Parent = Circle,
	})

	return Circle
end

--[[
	CHECKBOX
]]

function UILibrary.Checkbox(Config: {
	Checked: boolean?,
	Size: number?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	ZIndex: number?,
	Parent: Instance?,
}): TextButton
	local Size = Config.Size or 14
	local Checked = Config.Checked or false
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Checkbox = UIFactory.TextButton({
		Name = "Checkbox",
		Size = UDim2.fromOffset(Size, Size),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor = if Checked then Theme.Colors.Primary else Theme.Colors.BackgroundDark,
		Text = "",
		ZIndex = BaseZIndex,
		Corner = UDim.new(0, 3),
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})

	UIFactory.TextLabel({
		Name = "Checkmark",
		Text = "✓",
		Size = UDim2.fromScale(1, 1),
		TextColor = Theme.Colors.Text,
		Font = Theme.Fonts.Bold,
		TextSize = 10,
		Visible = Checked,
		ZIndex = BaseZIndex + 1,
		Parent = Checkbox,
	})

	return Checkbox
end

--[[
	COLOR PICKER COMPONENTS
]]

function UILibrary.ColorSwatch(Config: {
	Color: Color3,
	Size: UDim2?,
	ZIndex: number?,
	Parent: Instance?,
}): TextButton
	return UIFactory.TextButton({
		Name = "ColorSwatch",
		Size = Config.Size or UDim2.fromOffset(32, 32),
		BackgroundColor = Config.Color,
		Text = "",
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Parent = Config.Parent,
	})
end

function UILibrary.ColorPickerDropdown(Config: {
	ZIndex: number?,
	Parent: Instance?,
}): Frame
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel + 100

	local Dropdown = UIFactory.Frame({
		Name = "ColorDropdown",
		Size = UDim2.fromOffset(200, 80),
		Position = UDim2.new(0, 0, 1, 4),
		BackgroundColor = Theme.Colors.Surface,
		Visible = false,
		ZIndex = BaseZIndex,
		Corner = Theme.Sizes.BorderRadiusSmall,
		Stroke = Theme.Colors.Border,
		Parent = Config.Parent,
	})

	UIFactory.GridLayout({
		CellSize = UDim2.fromOffset(32, 32),
		CellPadding = UDim2.fromOffset(4, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = Dropdown,
	})

	UIFactory.Padding({
		All = UDim.new(0, 8),
		Parent = Dropdown,
	})

	return Dropdown
end

--[[
	SPACERS & DIVIDERS
]]

function UILibrary.Spacer(Config: { Height: number?, LayoutOrder: number?, Parent: Instance? }): Frame
	return UIFactory.Frame({
		Name = "Spacer",
		Size = UDim2.new(1, 0, 0, Config.Height or 8),
		BackgroundTransparency = 1,
		LayoutOrder = Config.LayoutOrder or 0,
		Parent = Config.Parent,
	})
end

function UILibrary.Divider(Config: { LayoutOrder: number?, ZIndex: number?, Parent: Instance? }): Frame
	return UIFactory.Frame({
		Name = "Divider",
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor = Theme.Colors.Border,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = Config.ZIndex or Theme.ZIndex.Panel,
		Parent = Config.Parent,
	})
end

--[[
	LOW-LEVEL PASS-THROUGHS
	For cases where you need direct access to UIFactory primitives
]]

function UILibrary.Stroke(Parent: Instance, StrokeColor: Color3?, Thickness: number?): UIStroke
	return UIFactory.Stroke(Parent, StrokeColor, Thickness)
end

function UILibrary.Corner(Parent: Instance, Radius: UDim | number | boolean): UICorner
	return UIFactory.Corner(Parent, Radius)
end

function UILibrary.Padding(Config: UIFactory.PaddingConfig): UIPadding
	return UIFactory.Padding(Config)
end

function UILibrary.ListLayout(Config: UIFactory.ListLayoutConfig): UIListLayout
	return UIFactory.ListLayout(Config)
end

function UILibrary.GridLayout(Config: UIFactory.GridLayoutConfig): UIGridLayout
	return UIFactory.GridLayout(Config)
end

function UILibrary.Scale(Parent: Instance, ScaleValue: number): UIScale
	return UIFactory.Scale(Parent, ScaleValue)
end

function UILibrary.ClickBlocker(Config: { Name: string?, ZIndex: number?, Parent: Instance? }): TextButton
	return UIFactory.ClickBlocker(Config)
end

function UILibrary.Overlay(Config: { ZIndex: number?, Parent: Instance? }): TextButton
	return UIFactory.Overlay(Config)
end

return UILibrary