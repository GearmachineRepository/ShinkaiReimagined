--!strict

local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)

local NodePalette = {}

export type NodePaletteConfig = {
	Parent: GuiObject?,
	OnNodeSelected: ((BlockType: string) -> ())?,
}

export type NodePaletteInstance = {
	Frame: Frame,
	Destroy: () -> (),
}

local CATEGORIES = {
	{ Name = "Flow", Types = { "Wait", "Branch" } },
	{ Name = "Combat", Types = { "Hitbox", "HitCancel", "AddHealth" } },
	{ Name = "Effects", Types = { "Animation", "Sound", "Velocity" } },
	{ Name = "Logic", Types = { "Signal", "AndGate", "OrGate", "NotGate", "Timer", "Counter" } },
	{ Name = "Advanced", Types = { "Skill" } },
}

function NodePalette.Create(Config: NodePaletteConfig): NodePaletteInstance
	local Container = Panel.Create({
		Name = "NodePalette",
		Size = UDim2.new(0, Theme.Sizes.PanelWidth, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
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
	HeaderTitle.Text = "Nodes"
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
		Padding = Theme.Sizes.PaddingSmall,
		Parent = Container,
	})

	Theme.ApplyListLayout(ContentScroll, Enum.FillDirection.Vertical, Theme.Sizes.GapSmall)

	local Connections: { RBXScriptConnection } = {}
	local CategoryOrder = 0

	for _, Category in CATEGORIES do
		CategoryOrder = CategoryOrder + 1

		local CategoryFrame = Instance.new("Frame")
		CategoryFrame.Name = "Category_" .. Category.Name
		CategoryFrame.Size = UDim2.fromScale(1, 0)
		CategoryFrame.AutomaticSize = Enum.AutomaticSize.Y
		CategoryFrame.BackgroundTransparency = 1
		CategoryFrame.LayoutOrder = CategoryOrder
		CategoryFrame.Parent = ContentScroll

		local CategoryLayout = Instance.new("UIListLayout")
		CategoryLayout.FillDirection = Enum.FillDirection.Vertical
		CategoryLayout.Padding = UDim.new(0, 2)
		CategoryLayout.Parent = CategoryFrame

		local CategoryLabel = Instance.new("TextLabel")
		CategoryLabel.Name = "CategoryLabel"
		CategoryLabel.Size = UDim2.new(1, 0, 0, 20)
		CategoryLabel.BackgroundTransparency = 1
		CategoryLabel.Text = Category.Name
		CategoryLabel.TextColor3 = Theme.Colors.TextMuted
		CategoryLabel.FontFace = Theme.Fonts.Bold
		CategoryLabel.TextSize = Theme.TextSizes.Small
		CategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
		CategoryLabel.LayoutOrder = 0
		CategoryLabel.Parent = CategoryFrame

		for TypeIndex, BlockType in Category.Types do
			local Definition = NodeRegistry.Get(BlockType)
			if not Definition then
				continue
			end

			local NodeButton = Instance.new("TextButton")
			NodeButton.Name = "Node_" .. BlockType
			NodeButton.Size = UDim2.new(1, 0, 0, 28)
			NodeButton.BackgroundColor3 = Theme.Colors.Surface
			NodeButton.BorderSizePixel = 0
			NodeButton.AutoButtonColor = false
			NodeButton.LayoutOrder = TypeIndex
			NodeButton.Parent = CategoryFrame

			Theme.ApplyCorner(NodeButton, Theme.Sizes.BorderRadiusSmall)

			local ColorBar = Instance.new("Frame")
			ColorBar.Name = "ColorBar"
			ColorBar.Size = UDim2.new(0, 4, 1, -4)
			ColorBar.Position = UDim2.fromOffset(2, 2)
			ColorBar.BackgroundColor3 = Definition.Color
			ColorBar.BorderSizePixel = 0
			ColorBar.Parent = NodeButton

			Theme.ApplyCorner(ColorBar, UDim.new(0, 2))

			local ButtonLabel = Instance.new("TextLabel")
			ButtonLabel.Name = "Label"
			ButtonLabel.Size = UDim2.new(1, -16, 1, 0)
			ButtonLabel.Position = UDim2.fromOffset(12, 0)
			ButtonLabel.BackgroundTransparency = 1
			ButtonLabel.Text = Definition.DisplayName
			ButtonLabel.TextColor3 = Theme.Colors.Text
			ButtonLabel.FontFace = Theme.Fonts.Default
			ButtonLabel.TextSize = Theme.TextSizes.Small
			ButtonLabel.TextXAlignment = Enum.TextXAlignment.Left
			ButtonLabel.Parent = NodeButton

			table.insert(Connections, NodeButton.MouseEnter:Connect(function()
				NodeButton.BackgroundColor3 = Theme.Colors.SurfaceHover
			end))

			table.insert(Connections, NodeButton.MouseLeave:Connect(function()
				NodeButton.BackgroundColor3 = Theme.Colors.Surface
			end))

			table.insert(Connections, NodeButton.MouseButton1Click:Connect(function()
				if Config.OnNodeSelected then
					Config.OnNodeSelected(BlockType)
				end
			end))
		end
	end

	local Instance: NodePaletteInstance = {
		Frame = Container,
	} :: any

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

return NodePalette