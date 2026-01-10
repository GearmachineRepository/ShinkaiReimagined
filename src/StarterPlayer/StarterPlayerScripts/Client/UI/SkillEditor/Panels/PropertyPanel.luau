--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Panel = require(script.Parent.Parent.Components.Panel)
local TextInput = require(script.Parent.Parent.Components.TextInput)
local NumberInput = require(script.Parent.Parent.Components.NumberInput)
local Toggle = require(script.Parent.Parent.Components.Toggle)
local Dropdown = require(script.Parent.Parent.Components.Dropdown)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)

local PropertyPanel = {}

export type PropertyPanelConfig = {
	Parent: GuiObject?,
	OnPropertyChanged: ((NodeId: string, Key: string, Value: any) -> ())?,
}

export type PropertyPanelInstance = {
	Frame: Frame,
	SetNode: (NodeData: Types.NodeInstance?) -> (),
	Refresh: () -> (),
	Destroy: () -> (),
}

function PropertyPanel.Create(Config: PropertyPanelConfig): PropertyPanelInstance
	local CurrentNode: Types.NodeInstance? = nil
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

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 36)
	Header.BackgroundColor3 = Theme.Colors.BackgroundDark
	Header.BorderSizePixel = 0
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
	HeaderTitle.Parent = Header

	local ContentScroll = Panel.CreateScrollable({
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor = Theme.Colors.Background,
		Padding = Theme.Sizes.Padding,
		Parent = Container,
	})

	Theme.ApplyListLayout(ContentScroll, Enum.FillDirection.Vertical, Theme.Sizes.Gap)

	local EmptyLabel = Instance.new("TextLabel")
	EmptyLabel.Name = "EmptyLabel"
	EmptyLabel.Size = UDim2.new(1, 0, 0, 40)
	EmptyLabel.BackgroundTransparency = 1
	EmptyLabel.Text = "Select a node to edit"
	EmptyLabel.TextColor3 = Theme.Colors.TextMuted
	EmptyLabel.FontFace = Theme.Fonts.Default
	EmptyLabel.TextSize = Theme.TextSizes.Default
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
		local Row = Instance.new("Frame")
		Row.Name = "Property_" .. PropertyDef.Key
		Row.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight + 20)
		Row.BackgroundTransparency = 1
		Row.LayoutOrder = LayoutOrder
		Row.Parent = ContentScroll

		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.Size = UDim2.new(1, 0, 0, 16)
		Label.BackgroundTransparency = 1
		Label.Text = PropertyDef.Label
		Label.TextColor3 = Theme.Colors.TextMuted
		Label.FontFace = Theme.Fonts.Default
		Label.TextSize = Theme.TextSizes.Small
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.Parent = Row

		local InputContainer = Instance.new("Frame")
		InputContainer.Name = "InputContainer"
		InputContainer.Size = UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
		InputContainer.Position = UDim2.fromOffset(0, 8)
		InputContainer.BackgroundTransparency = 1
		InputContainer.Parent = Row

		local InputInstance: any = nil

		if PropertyDef.Type == "String" or PropertyDef.Type == "AssetId" then
			InputInstance = TextInput.Create({
				Text = tostring(Value or ""),
				PlaceholderText = PropertyDef.Type == "AssetId" and "rbxassetid://..." or "",
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
		NodeTypeLabel.Parent = ContentScroll
		table.insert(PropertyInputs, { Frame = NodeTypeLabel })

		for Index, PropertyDef in Definition.Properties do
			local Value = CurrentNode.Properties[PropertyDef.Key]
			CreatePropertyRow(PropertyDef, Value, Index)
		end
	end

	local Instance: PropertyPanelInstance = {
		Frame = Container,
	} :: any

	function Instance.SetNode(NodeData: Types.NodeInstance?)
		CurrentNode = NodeData
		BuildProperties()
	end

	function Instance.Refresh()
		BuildProperties()
	end

	function Instance.Destroy()
		ClearProperties()
		Container:Destroy()
	end

	return Instance
end

return PropertyPanel