--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local UILibrary = require(script.Parent.Parent.UILibrary)
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
	Parent: Instance?,
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
	local PropertyInputsByKey: { [string]: any } = {}

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

	local Header = UILibrary.SurfaceContainer({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Container,
	})
	Header.BackgroundColor3 = Theme.Colors.BackgroundDark

	local Stroke = Header:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke:Destroy()
	end

	UILibrary.HeaderLabel({
		Name = "Title",
		Text = "Properties",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Header,
	})

	local ContentScroll = Panel.CreateScrollable({
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor = Theme.Colors.Background,
		Padding = Theme.Sizes.Padding,
		Parent = Container,
	})
	ContentScroll.ZIndex = Theme.ZIndex.Panel

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = Theme.Sizes.GapLarge,
		Parent = ContentScroll,
	})

	local EmptyLabel = UILibrary.BodyLabel({
		Name = "EmptyLabel",
		Text = "Select a node to edit",
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = Theme.ZIndex.Panel,
		Parent = ContentScroll,
	})
	EmptyLabel.TextColor3 = Theme.Colors.TextMuted

	local function ClearProperties()
		for _, Input in PropertyInputs do
			if Input.Destroy then
				Input.Destroy()
			elseif Input.Frame then
				Input.Frame:Destroy()
			end
		end
		table.clear(PropertyInputs)
		table.clear(PropertyInputsByKey)
	end

	local function CreatePropertyRow(PropertyDef: Types.PropertyDefinition, Value: any, LayoutOrder: number)
		local RowHeight = Theme.Sizes.InputHeight + 24

		local Row = UILibrary.TransparentContainer({
			Name = "Property_" .. PropertyDef.Key,
			Size = UDim2.new(1, 0, 0, RowHeight),
			LayoutOrder = LayoutOrder,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})

		local Label = UILibrary.PropertyLabel({
			Name = "Label",
			Text = PropertyDef.Label,
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromOffset(0, 0),
			ZIndex = Theme.ZIndex.Panel,
			Parent = Row,
		})

		if PropertyDef.Tooltip then
			Label.Active = true
			Tooltip.Bind(Label, PropertyDef.Tooltip)
		end

		local InputContainer = UILibrary.TransparentContainer({
			Name = "InputContainer",
			Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
			Position = UDim2.fromOffset(0, 20),
			ZIndex = Theme.ZIndex.Panel,
			Parent = Row,
		})

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
			PropertyInputsByKey[PropertyDef.Key] = InputInstance
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

		local NodeTypeLabel = UILibrary.HeaderLabel({
			Name = "NodeType",
			Text = Definition.DisplayName,
			Size = UDim2.new(1, 0, 0, 24),
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})
		NodeTypeLabel.TextColor3 = Definition.Color
		NodeTypeLabel.LayoutOrder = 0
		table.insert(PropertyInputs, { Frame = NodeTypeLabel })

		local PropertyStartIndex = 1

		if Definition.Description then
			local DescriptionLabel = UILibrary.BodyLabel({
				Name = "Description",
				Text = Definition.Description,
				Size = UDim2.fromScale(1, 0),
				ZIndex = Theme.ZIndex.Panel,
				Parent = ContentScroll,
			})
			DescriptionLabel.AutomaticSize = Enum.AutomaticSize.Y
			DescriptionLabel.TextColor3 = Theme.Colors.TextMuted
			DescriptionLabel.TextSize = Theme.TextSizes.Small
			DescriptionLabel.LayoutOrder = 1
			table.insert(PropertyInputs, { Frame = DescriptionLabel })
			PropertyStartIndex = 2
		end

		for Index, PropertyDef in Definition.Properties do
			local Value = CurrentNode.Properties[PropertyDef.Key]
			CreatePropertyRow(PropertyDef, Value, Index + PropertyStartIndex - 1)
		end

		local Spacer = UILibrary.Spacer({
			Height = 8,
			LayoutOrder = #Definition.Properties + PropertyStartIndex,
			Parent = ContentScroll,
		})
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

		local CommentHeader = UILibrary.HeaderLabel({
			Name = "CommentHeader",
			Text = "Comment",
			Size = UDim2.new(1, 0, 0, 24),
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})
		CommentHeader.LayoutOrder = 0
		table.insert(PropertyInputs, { Frame = CommentHeader })

		local TitleRow = UILibrary.TransparentContainer({
			Name = "Property_Title",
			Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight + 24),
			LayoutOrder = 1,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})

		UILibrary.PropertyLabel({
			Name = "Label",
			Text = "Title",
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = Theme.ZIndex.Panel,
			Parent = TitleRow,
		})

		local TitleContainer = UILibrary.TransparentContainer({
			Name = "InputContainer",
			Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
			Position = UDim2.fromOffset(0, 20),
			ZIndex = Theme.ZIndex.Panel,
			Parent = TitleRow,
		})

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
		PropertyInputsByKey["Title"] = TitleInput
		table.insert(PropertyInputs, { Frame = TitleRow })

		local TextRow = UILibrary.TransparentContainer({
			Name = "Property_Text",
			Size = UDim2.new(1, 0, 0, 80 + 24),
			LayoutOrder = 2,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})

		UILibrary.PropertyLabel({
			Name = "Label",
			Text = "Body",
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = Theme.ZIndex.Panel,
			Parent = TextRow,
		})

		local TextContainer = UILibrary.TransparentContainer({
			Name = "InputContainer",
			Size = UDim2.new(1, 0, 0, 80),
			Position = UDim2.fromOffset(0, 20),
			ZIndex = Theme.ZIndex.Panel,
			Parent = TextRow,
		})

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

		UILibrary.Corner(TextInputBox, Theme.Sizes.BorderRadiusSmall)
		UILibrary.Stroke(TextInputBox, Theme.Colors.Border)
		UILibrary.Padding({
			All = UDim.new(0, 8),
			Parent = TextInputBox,
		})

		TextInputBox.FocusLost:Connect(function()
			if CurrentComment and Config.OnCommentPropertyChanged then
				Config.OnCommentPropertyChanged(CurrentComment.CommentId, "Text", TextInputBox.Text)
			end
		end)

		table.insert(PropertyInputs, { Frame = TextRow })

		local ColorRow = UILibrary.TransparentContainer({
			Name = "Property_Color",
			Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight + 24),
			LayoutOrder = 3,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})

		UILibrary.PropertyLabel({
			Name = "Label",
			Text = "Color",
			Size = UDim2.new(1, 0, 0, 18),
			ZIndex = Theme.ZIndex.Panel,
			Parent = ColorRow,
		})

		local ColorContainer = UILibrary.TransparentContainer({
			Name = "InputContainer",
			Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
			Position = UDim2.fromOffset(0, 20),
			ZIndex = Theme.ZIndex.Panel,
			Parent = ColorRow,
		})

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
		PropertyInputsByKey["Color"] = ColorInput
		table.insert(PropertyInputs, { Frame = ColorRow })

		local Spacer = UILibrary.Spacer({
			Height = 8,
			LayoutOrder = 4,
			Parent = ContentScroll,
		})
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
		local Input = PropertyInputsByKey[Key]
		if Input then
			if Input.SetValue then
				Input.SetValue(Value)
			elseif Input.SetText then
				Input.SetText(tostring(Value or ""))
			elseif Input.SetSelected then
				Input.SetSelected(Value)
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