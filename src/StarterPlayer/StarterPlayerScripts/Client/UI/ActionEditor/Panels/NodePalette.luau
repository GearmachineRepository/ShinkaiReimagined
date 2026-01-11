--!strict

local Theme = require(script.Parent.Parent.Theme)
local Panel = require(script.Parent.Parent.Components.Panel)
local Tooltip = require(script.Parent.Parent.Components.Tooltip)
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

local COMMENT_DEFINITION = {
	BlockType = "Comment",
	DisplayName = "Comment",
	Description = "A visual note for organizing and documenting your Action graph.",
	Color = Color3.fromRGB(90, 90, 95),
}

function NodePalette.Create(Config: NodePaletteConfig): NodePaletteInstance
	local Container = Panel.Create({
		Name = "NodePalette",
		Size = UDim2.new(0, Theme.Sizes.PanelWidth, 1, -200),
		Position = UDim2.new(0, 0, 0, 0),
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
	HeaderTitle.Text = "Nodes"
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
		Padding = Theme.Sizes.PaddingSmall,
		Parent = Container,
	})
	ContentScroll.ZIndex = Theme.ZIndex.Panel

	Theme.ApplyListLayout(ContentScroll, Enum.FillDirection.Vertical, Theme.Sizes.GapSmall)

	local Connections: { RBXScriptConnection } = {}
	local TooltipCleanups: { () -> () } = {}
	local CategoryOrder = 0

	local Categories = NodeRegistry.GetCategories()

	for _, Category in Categories do
		CategoryOrder = CategoryOrder + 1

		local CategoryFrame = Instance.new("Frame")
		CategoryFrame.Name = "Category_" .. Category.Name
		CategoryFrame.Size = UDim2.fromScale(1, 0)
		CategoryFrame.AutomaticSize = Enum.AutomaticSize.Y
		CategoryFrame.BackgroundTransparency = 1
		CategoryFrame.LayoutOrder = CategoryOrder
		CategoryFrame.ZIndex = Theme.ZIndex.Panel
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
		CategoryLabel.ZIndex = Theme.ZIndex.Panel
		CategoryLabel.Parent = CategoryFrame

		for TypeIndex, BlockType in Category.Types do
			if BlockType == "BranchStart" then
				continue
			end

			local Definition = nil
			if BlockType == "Comment" then
				Definition = COMMENT_DEFINITION
			else
				Definition = NodeRegistry.Get(BlockType) :: any
			end

			if not Definition then
				continue
			end

			local NodeButton = Instance.new("TextButton")
			NodeButton.Name = "Node_" .. BlockType
			NodeButton.Size = UDim2.new(1, 0, 0, 28)
			NodeButton.BackgroundColor3 = Theme.Colors.Surface
			NodeButton.BorderSizePixel = 0
			NodeButton.AutoButtonColor = false
			NodeButton.Text = ""
			NodeButton.LayoutOrder = TypeIndex
			NodeButton.ZIndex = Theme.ZIndex.Panel
			NodeButton.Parent = CategoryFrame

			Theme.ApplyCorner(NodeButton, Theme.Sizes.BorderRadiusSmall)

			local ColorBar = Instance.new("Frame")
			ColorBar.Name = "ColorBar"
			ColorBar.Size = UDim2.new(0, 3, 1, -4)
			ColorBar.Position = UDim2.fromOffset(2, 2)
			ColorBar.BackgroundColor3 = Definition.Color
			ColorBar.BorderSizePixel = 0
			ColorBar.ZIndex = Theme.ZIndex.Panel + 1
			ColorBar.Parent = NodeButton

			Theme.ApplyCorner(ColorBar)

			local NodeLabel = Instance.new("TextLabel")
			NodeLabel.Name = "Label"
			NodeLabel.Size = UDim2.new(1, -16, 1, 0)
			NodeLabel.Position = UDim2.fromOffset(12, 0)
			NodeLabel.BackgroundTransparency = 1
			NodeLabel.Text = Definition.DisplayName
			NodeLabel.TextColor3 = Theme.Colors.Text
			NodeLabel.FontFace = Theme.Fonts.Default
			NodeLabel.TextSize = Theme.TextSizes.Default
			NodeLabel.TextXAlignment = Enum.TextXAlignment.Left
			NodeLabel.ZIndex = Theme.ZIndex.Panel + 1
			NodeLabel.Parent = NodeButton

			local Cleanup = Tooltip.Bind(NodeButton, Definition.Description or "")
			table.insert(TooltipCleanups, Cleanup)

			table.insert(Connections, NodeButton.MouseEnter:Connect(function()
				NodeButton.BackgroundColor3 = Theme.Colors.SurfaceHover
			end))

			table.insert(Connections, NodeButton.MouseLeave:Connect(function()
				NodeButton.BackgroundColor3 = Theme.Colors.Surface
			end))

			table.insert(Connections, NodeButton.Activated:Connect(function()
				if Config.OnNodeSelected then
					Config.OnNodeSelected(BlockType)
				end
			end))
		end
	end

	local function Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)

		for _, Cleanup in TooltipCleanups do
			Cleanup()
		end
		table.clear(TooltipCleanups)

		Container:Destroy()
	end

	return {
		Frame = Container,
		Destroy = Destroy,
	}
end

return NodePalette