--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Panel = require(script.Parent.Parent.Components.Panel)
local Button = require(script.Parent.Parent.Components.Button)
local TextInput = require(script.Parent.Parent.Components.TextInput)
local NumberInput = require(script.Parent.Parent.Components.NumberInput)
local Toggle = require(script.Parent.Parent.Components.Toggle)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local ColorPicker = require(script.Parent.Parent.Components.ColorPicker)
local Tooltip = require(script.Parent.Parent.Components.Tooltip)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)

local PropertyPanel = {}

export type PropertyPanelConfig = {
	Parent: GuiObject?,
	OnPropertyChanged: ((NodeId: string, Key: string, Value: any) -> ())?,
	OnNodeDelete: ((NodeId: string) -> ())?,
	OnCommentPropertyChanged: ((CommentId: string, Key: string, Value: any) -> ())?,
	OnCommentDelete: ((CommentId: string) -> ())?,
	GetBranchOptions: (() -> { string })?,
}

export type PropertyPanelInstance = {
	Frame: Frame,
	SetNode: (NodeData: Types.NodeInstance?) -> (),
	SetComment: (CommentData: Types.CommentData?) -> (),
	RefreshProperty: (Key: string, Value: any) -> (),
	Refresh: () -> (),
	Destroy: () -> (),
}

function PropertyPanel.Create(Config: PropertyPanelConfig): PropertyPanelInstance
	local CurrentNode: Types.NodeInstance? = nil
	local CurrentComment: Types.CommentData? = nil
	local PropertyInputs: { any } = {}

	local Container = Panel.Create({
		Name = "PropertyPanel",
		Size = UDim2.new(0, Theme.Sizes.PanelWidth, 1, 0),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor = Theme.Colors.Background,
		BorderColor = Theme.Colors.Border,
		Parent = Config.Parent,
	})
	Container.ZIndex = Theme.ZIndex.Panel

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 36)
	Header.BackgroundColor3 = Theme.Colors.BackgroundDark
	Header.BorderSizePixel = 0
	Header.ZIndex = Theme.ZIndex.Panel
	Header.Parent = Container

	local HeaderTitle = Instance.new("TextLabel")
	HeaderTitle.Name = "Title"
	HeaderTitle.Size = UDim2.new(1, -16, 1, 0)
	HeaderTitle.Position = UDim2.fromOffset(8, 0)
	HeaderTitle.BackgroundTransparency = 1
	HeaderTitle.Text = "Properties"
	HeaderTitle.TextColor3 = Theme.Colors.Text
	HeaderTitle.FontFace = Theme.Fonts.Bold
	HeaderTitle.TextSize = Theme.TextSizes.Default
	HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
	HeaderTitle.ZIndex = Theme.ZIndex.Panel
	HeaderTitle.Parent = Header

	local ContentScroll = Panel.CreateScrollable({
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor = Theme.Colors.Background,
		Padding = Theme.Sizes.Padding,
		Parent = Container,
	})
	ContentScroll.ZIndex = Theme.ZIndex.Panel

	Theme.ApplyListLayout(ContentScroll, Enum.FillDirection.Vertical, Theme.Sizes.GapLarge)

	local EmptyLabel = Instance.new("TextLabel")
	EmptyLabel.Name = "EmptyLabel"
	EmptyLabel.Size = UDim2.new(1, 0, 0, 40)
	EmptyLabel.BackgroundTransparency = 1
	EmptyLabel.Text = "Select a node to edit"
	EmptyLabel.TextColor3 = Theme.Colors.TextMuted
	EmptyLabel.FontFace = Theme.Fonts.Default
	EmptyLabel.TextSize = Theme.TextSizes.Default
	EmptyLabel.ZIndex = Theme.ZIndex.Panel
	EmptyLabel.Parent = ContentScroll

	local function ClearProperties()
		for _, Input in PropertyInputs do
			if Input.Destroy then
				Input.Destroy()
			elseif Input.Frame then
				Input.Frame:Destroy()
			end
		end
		table.clear(PropertyInputs)
	end

	local function CreatePropertyRow(PropertyDef: Types.PropertyDefinition, Value: any, LayoutOrder: number)
		local RowHeight = Theme.Sizes.InputHeight + 24

		local Row = Instance.new("Frame")
		Row.Name = "Property_" .. PropertyDef.Key
		Row.Size = UDim2.new(1, 0, 0, RowHeight)
		Row.BackgroundTransparency = 1
		Row.LayoutOrder = LayoutOrder
		Row.ZIndex = Theme.ZIndex.Panel
		Row.Parent = ContentScroll

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, 0, 0, 18)
		Label.Position = UDim2.fromOffset(0, 0)
		Label.BackgroundTransparency = 1
		Label.Text = PropertyDef.Label
		Label.TextColor3 = Theme.Colors.TextMuted
		Label.FontFace = Theme.Fonts.Default
		Label.TextSize = Theme.TextSizes.Small
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.ZIndex = Theme.ZIndex.Panel
		Label.Parent = Row

		if PropertyDef.Tooltip then
			Label.Active = true
			Tooltip.Bind(Label, PropertyDef.Tooltip)
		end

		local InputContainer = Instance.new("Frame")
		InputContainer.Name = "InputContainer"
		InputContainer.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
		InputContainer.Position = UDim2.fromOffset(0, 20)
		InputContainer.BackgroundTransparency = 1
		InputContainer.ZIndex = Theme.ZIndex.Panel
		InputContainer.Parent = Row

		local InputInstance: any = nil

		if PropertyDef.Type == "String" or PropertyDef.Type == "AssetId" then
			InputInstance = TextInput.Create({
				Text = tostring(Value or ""),
				PlaceholderText = PropertyDef.Type == "AssetId" and "rbxassetid://..." or "",
				ZIndex = Theme.ZIndex.Panel,
				Parent = InputContainer,
				OnFocusLost = function(Text: string)
					if CurrentNode and Config.OnPropertyChanged then
						Config.OnPropertyChanged(CurrentNode.NodeId, PropertyDef.Key, Text)
					end
				end,
			})

		elseif PropertyDef.Type == "Number" then
			InputInstance = NumberInput.Create({
				Value = tonumber(Value) or PropertyDef.Default,
				Min = PropertyDef.Min,
				Max = PropertyDef.Max,
				ZIndex = Theme.ZIndex.Panel,
				Parent = InputContainer,
				OnChanged = function(NewValue: number)
					if CurrentNode and Config.OnPropertyChanged then
						Config.OnPropertyChanged(CurrentNode.NodeId, PropertyDef.Key, NewValue)
					end
				end,
			})

		elseif PropertyDef.Type == "Boolean" then
			InputInstance = Toggle.Create({
				Value = if Value ~= nil then Value else PropertyDef.Default,
				ZIndex = Theme.ZIndex.Panel,
				Parent = InputContainer,
				OnChanged = function(NewValue: boolean)
					if CurrentNode and Config.OnPropertyChanged then
						Config.OnPropertyChanged(CurrentNode.NodeId, PropertyDef.Key, NewValue)
					end
				end,
			})

		elseif PropertyDef.Type == "Dropdown" then
			InputInstance = Dropdown.Create({
				Options = PropertyDef.Options or {},
				Selected = Value,
				ZIndex = Theme.ZIndex.Panel,
				Parent = InputContainer,
				OnSelected = function(Option: string)
					if CurrentNode and Config.OnPropertyChanged then
						Config.OnPropertyChanged(CurrentNode.NodeId, PropertyDef.Key, Option)
					end
				end,
			})

		elseif PropertyDef.Type == "BranchDropdown" then
			local BranchOptions = if Config.GetBranchOptions then Config.GetBranchOptions() else {}
			InputInstance = Dropdown.Create({
				Options = BranchOptions,
				Selected = Value,
				ZIndex = Theme.ZIndex.Panel,
				Parent = InputContainer,
				OnSelected = function(Option: string)
					if CurrentNode and Config.OnPropertyChanged then
						Config.OnPropertyChanged(CurrentNode.NodeId, PropertyDef.Key, Option)
					end
				end,
			})
		end

		if InputInstance then
			table.insert(PropertyInputs, InputInstance)
		end
		table.insert(PropertyInputs, { Frame = Row })
	end

	local function BuildProperties()
		ClearProperties()

		if not CurrentNode then
			EmptyLabel.Visible = true
			return
		end

		EmptyLabel.Visible = false

		local Definition = NodeRegistry.Get(CurrentNode.BlockType)
		if not Definition then
			return
		end

		local NodeTypeLabel = Instance.new("TextLabel")
		NodeTypeLabel.Name = "NodeType"
		NodeTypeLabel.Size = UDim2.new(1, 0, 0, 24)
		NodeTypeLabel.BackgroundTransparency = 1
		NodeTypeLabel.Text = Definition.DisplayName
		NodeTypeLabel.TextColor3 = Definition.Color
		NodeTypeLabel.FontFace = Theme.Fonts.Bold
		NodeTypeLabel.TextSize = Theme.TextSizes.Large
		NodeTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
		NodeTypeLabel.LayoutOrder = 0
		NodeTypeLabel.ZIndex = Theme.ZIndex.Panel
		NodeTypeLabel.Parent = ContentScroll
		table.insert(PropertyInputs, { Frame = NodeTypeLabel })

		local PropertyStartIndex = 1

		if Definition.Description then
			local DescriptionLabel = Instance.new("TextLabel")
			DescriptionLabel.Name = "Description"
			DescriptionLabel.Size = UDim2.fromScale(1, 0)
			DescriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
			DescriptionLabel.BackgroundTransparency = 1
			DescriptionLabel.Text = Definition.Description
			DescriptionLabel.TextColor3 = Theme.Colors.TextMuted
			DescriptionLabel.FontFace = Theme.Fonts.Default
			DescriptionLabel.TextSize = Theme.TextSizes.Small
			DescriptionLabel.TextWrapped = true
			DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
			DescriptionLabel.LayoutOrder = 1
			DescriptionLabel.ZIndex = Theme.ZIndex.Panel
			DescriptionLabel.Parent = ContentScroll
			table.insert(PropertyInputs, { Frame = DescriptionLabel })
			PropertyStartIndex = 2
		end

		for Index, PropertyDef in Definition.Properties do
			local Value = CurrentNode.Properties[PropertyDef.Key]
			CreatePropertyRow(PropertyDef, Value, Index + PropertyStartIndex - 1)
		end

		local Spacer = Instance.new("Frame")
		Spacer.Name = "Spacer"
		Spacer.Size = UDim2.new(1, 0, 0, 8)
		Spacer.BackgroundTransparency = 1
		Spacer.LayoutOrder = #Definition.Properties + PropertyStartIndex
		Spacer.Parent = ContentScroll
		table.insert(PropertyInputs, { Frame = Spacer })

		if CurrentNode.BlockType ~= "BranchStart" then
			local DeleteButton = Button.Create({
				Name = "DeleteNode",
				Text = "Delete Node",
				Size = UDim2.new(1, 0, 0, 32),
				BackgroundColor = Theme.Colors.Error,
				ZIndex = Theme.ZIndex.Panel,
				Parent = ContentScroll,
				OnClick = function()
					if CurrentNode and Config.OnNodeDelete then
						Config.OnNodeDelete(CurrentNode.NodeId)
					end
				end,
			})
			DeleteButton.Frame.LayoutOrder = #Definition.Properties + PropertyStartIndex + 1
			table.insert(PropertyInputs, DeleteButton)
		end
	end

	local function BuildCommentProperties()
		ClearProperties()

		if not CurrentComment then
			EmptyLabel.Visible = true
			return
		end

		EmptyLabel.Visible = false

		local CommentHeader = Instance.new("TextLabel")
		CommentHeader.Name = "CommentHeader"
		CommentHeader.Size = UDim2.new(1, 0, 0, 24)
		CommentHeader.BackgroundTransparency = 1
		CommentHeader.Text = "Comment"
		CommentHeader.TextColor3 = Theme.Colors.Text
		CommentHeader.FontFace = Theme.Fonts.Bold
		CommentHeader.TextSize = Theme.TextSizes.Large
		CommentHeader.TextXAlignment = Enum.TextXAlignment.Left
		CommentHeader.LayoutOrder = 0
		CommentHeader.ZIndex = Theme.ZIndex.Panel
		CommentHeader.Parent = ContentScroll
		table.insert(PropertyInputs, { Frame = CommentHeader })

		local TitleRow = Instance.new("Frame")
		TitleRow.Name = "Property_Title"
		TitleRow.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight + 24)
		TitleRow.BackgroundTransparency = 1
		TitleRow.LayoutOrder = 1
		TitleRow.ZIndex = Theme.ZIndex.Panel
		TitleRow.Parent = ContentScroll

		local TitleLabel = Instance.new("TextLabel")
		TitleLabel.Name = "Label"
		TitleLabel.Size = UDim2.new(1, 0, 0, 18)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Text = "Title"
		TitleLabel.TextColor3 = Theme.Colors.TextMuted
		TitleLabel.FontFace = Theme.Fonts.Default
		TitleLabel.TextSize = Theme.TextSizes.Small
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		TitleLabel.ZIndex = Theme.ZIndex.Panel
		TitleLabel.Parent = TitleRow

		local TitleContainer = Instance.new("Frame")
		TitleContainer.Name = "InputContainer"
		TitleContainer.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
		TitleContainer.Position = UDim2.fromOffset(0, 20)
		TitleContainer.BackgroundTransparency = 1
		TitleContainer.ZIndex = Theme.ZIndex.Panel
		TitleContainer.Parent = TitleRow

		local TitleInput = TextInput.Create({
			Text = CurrentComment.Title,
			PlaceholderText = "Title...",
			ZIndex = Theme.ZIndex.Panel,
			Parent = TitleContainer,
			OnFocusLost = function(Text: string)
				if CurrentComment and Config.OnCommentPropertyChanged then
					Config.OnCommentPropertyChanged(CurrentComment.CommentId, "Title", Text)
				end
			end,
		})
		table.insert(PropertyInputs, TitleInput)
		table.insert(PropertyInputs, { Frame = TitleRow })

		local TextRow = Instance.new("Frame")
		TextRow.Name = "Property_Text"
		TextRow.Size = UDim2.new(1, 0, 0, 80 + 24)
		TextRow.BackgroundTransparency = 1
		TextRow.LayoutOrder = 2
		TextRow.ZIndex = Theme.ZIndex.Panel
		TextRow.Parent = ContentScroll

		local TextLabel = Instance.new("TextLabel")
		TextLabel.Name = "Label"
		TextLabel.Size = UDim2.new(1, 0, 0, 18)
		TextLabel.BackgroundTransparency = 1
		TextLabel.Text = "Body"
		TextLabel.TextColor3 = Theme.Colors.TextMuted
		TextLabel.FontFace = Theme.Fonts.Default
		TextLabel.TextSize = Theme.TextSizes.Small
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		TextLabel.ZIndex = Theme.ZIndex.Panel
		TextLabel.Parent = TextRow

		local TextContainer = Instance.new("Frame")
		TextContainer.Name = "InputContainer"
		TextContainer.Size = UDim2.new(1, 0, 0, 80)
		TextContainer.Position = UDim2.fromOffset(0, 20)
		TextContainer.BackgroundTransparency = 1
		TextContainer.ZIndex = Theme.ZIndex.Panel
		TextContainer.Parent = TextRow

		local TextInputBox = Instance.new("TextBox")
		TextInputBox.Name = "TextInput"
		TextInputBox.Size = UDim2.fromScale(1, 1)
		TextInputBox.BackgroundColor3 = Theme.Colors.BackgroundDark
		TextInputBox.BorderSizePixel = 0
		TextInputBox.Text = CurrentComment.Text
		TextInputBox.PlaceholderText = "Comment body..."
		TextInputBox.TextColor3 = Theme.Colors.Text
		TextInputBox.PlaceholderColor3 = Theme.Colors.TextMuted
		TextInputBox.FontFace = Theme.Fonts.Default
		TextInputBox.TextSize = Theme.TextSizes.Default
		TextInputBox.TextXAlignment = Enum.TextXAlignment.Left
		TextInputBox.TextYAlignment = Enum.TextYAlignment.Top
		TextInputBox.ClearTextOnFocus = false
		TextInputBox.MultiLine = true
		TextInputBox.TextWrapped = true
		TextInputBox.ZIndex = Theme.ZIndex.Panel
		TextInputBox.Parent = TextContainer

		Theme.ApplyCorner(TextInputBox, Theme.Sizes.BorderRadiusSmall)
		Theme.ApplyStroke(TextInputBox, Theme.Colors.Border)
		Theme.ApplyPadding(TextInputBox, UDim.new(0, 8))

		TextInputBox.FocusLost:Connect(function()
			if CurrentComment and Config.OnCommentPropertyChanged then
				Config.OnCommentPropertyChanged(CurrentComment.CommentId, "Text", TextInputBox.Text)
			end
		end)

		table.insert(PropertyInputs, { Frame = TextRow })

		local ColorRow = Instance.new("Frame")
		ColorRow.Name = "Property_Color"
		ColorRow.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight + 24)
		ColorRow.BackgroundTransparency = 1
		ColorRow.LayoutOrder = 3
		ColorRow.ZIndex = Theme.ZIndex.Panel
		ColorRow.Parent = ContentScroll

		local ColorLabel = Instance.new("TextLabel")
		ColorLabel.Name = "Label"
		ColorLabel.Size = UDim2.new(1, 0, 0, 18)
		ColorLabel.BackgroundTransparency = 1
		ColorLabel.Text = "Color"
		ColorLabel.TextColor3 = Theme.Colors.TextMuted
		ColorLabel.FontFace = Theme.Fonts.Default
		ColorLabel.TextSize = Theme.TextSizes.Small
		ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
		ColorLabel.ZIndex = Theme.ZIndex.Panel
		ColorLabel.Parent = ColorRow

		local ColorContainer = Instance.new("Frame")
		ColorContainer.Name = "InputContainer"
		ColorContainer.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
		ColorContainer.Position = UDim2.fromOffset(0, 20)
		ColorContainer.BackgroundTransparency = 1
		ColorContainer.ZIndex = Theme.ZIndex.Panel
		ColorContainer.Parent = ColorRow

		local ColorInput = ColorPicker.Create({
			Color = CurrentComment.Color,
			ZIndex = Theme.ZIndex.Panel + 50,
			Parent = ColorContainer,
			OnChanged = function(Color: Color3)
				if CurrentComment and Config.OnCommentPropertyChanged then
					Config.OnCommentPropertyChanged(CurrentComment.CommentId, "Color", Color)
				end
			end,
		})
		table.insert(PropertyInputs, ColorInput)
		table.insert(PropertyInputs, { Frame = ColorRow })

		local Spacer = Instance.new("Frame")
		Spacer.Name = "Spacer"
		Spacer.Size = UDim2.new(1, 0, 0, 8)
		Spacer.BackgroundTransparency = 1
		Spacer.LayoutOrder = 4
		Spacer.Parent = ContentScroll
		table.insert(PropertyInputs, { Frame = Spacer })

		local DeleteButton = Button.Create({
			Name = "DeleteComment",
			Text = "Delete Comment",
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor = Theme.Colors.Error,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
			OnClick = function()
				if CurrentComment and Config.OnCommentDelete then
					Config.OnCommentDelete(CurrentComment.CommentId)
				end
			end,
		})
		DeleteButton.Frame.LayoutOrder = 5
		table.insert(PropertyInputs, DeleteButton)
	end

	local PanelInstance: PropertyPanelInstance = {
		Frame = Container,
	} :: any

	function PanelInstance.RefreshProperty(Key: string, Value: any)
		for _, Input in PropertyInputs do
			if Input.Key == Key then
				if Input.SetValue then
					Input.SetValue(Value)
				end
				break
			end
		end
	end

	function PanelInstance.SetNode(NodeData: Types.NodeInstance?)
		CurrentNode = NodeData
		CurrentComment = nil
		BuildProperties()
	end

	function PanelInstance.SetComment(CommentData: Types.CommentData?)
		CurrentComment = CommentData
		CurrentNode = nil
		BuildCommentProperties()
	end

	function PanelInstance.Refresh()
		if CurrentComment then
			BuildCommentProperties()
		else
			BuildProperties()
		end
	end

	function PanelInstance.Destroy()
		ClearProperties()
		Container:Destroy()
	end

	return PanelInstance
end

return PropertyPanel