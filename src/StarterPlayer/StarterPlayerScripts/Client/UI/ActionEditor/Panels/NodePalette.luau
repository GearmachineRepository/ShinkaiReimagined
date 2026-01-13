--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local Panel = require(script.Parent.Parent.Components.Panel)
local Tooltip = require(script.Parent.Parent.Components.Tooltip)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)

local NodePalette = {}

export type NodePaletteConfig = {
	Parent: Instance?,
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
		Text = "Nodes",
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
		Padding = Theme.Sizes.PaddingSmall,
		Parent = Container,
	})
	ContentScroll.ZIndex = Theme.ZIndex.Panel

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = Theme.Sizes.GapSmall,
		Parent = ContentScroll,
	})

	local Connections: { RBXScriptConnection } = {}
	local TooltipCleanups: { () -> () } = {}
	local CategoryOrder = 0

	local Categories = NodeRegistry.GetCategories()

	for _, Category in Categories do
		CategoryOrder = CategoryOrder + 1

		local CategoryFrame = UILibrary.TransparentContainer({
			Name = "Category_" .. Category.Name,
			Size = UDim2.fromScale(1, 0),
			LayoutOrder = CategoryOrder,
			ZIndex = Theme.ZIndex.Panel,
			Parent = ContentScroll,
		})
		CategoryFrame.AutomaticSize = Enum.AutomaticSize.Y

		UILibrary.ListLayout({
			Direction = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, 2),
			Parent = CategoryFrame,
		})

		local CategoryLabel = UILibrary.SectionLabel({
			Name = "CategoryLabel",
			Text = Category.Name,
			Size = UDim2.new(1, 0, 0, 20),
			ZIndex = Theme.ZIndex.Panel,
			Parent = CategoryFrame,
		})
		CategoryLabel.LayoutOrder = 0

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

			local NodeButton = UILibrary.ListItemButton({
				Name = "Node_" .. BlockType,
				Text = Definition.DisplayName,
				Size = UDim2.new(1, 0, 0, 28),
				ShowColorBar = true,
				BarColor = Definition.Color,
				LayoutOrder = TypeIndex,
				ZIndex = Theme.ZIndex.Panel,
				Parent = CategoryFrame,
			})

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