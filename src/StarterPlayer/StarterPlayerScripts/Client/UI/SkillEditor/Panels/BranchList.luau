--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Panel = require(script.Parent.Parent.Components.Panel)
local Button = require(script.Parent.Parent.Components.Button)

local BranchList = {}

export type BranchListConfig = {
	Parent: GuiObject?,
	OnBranchSelected: ((BranchId: string) -> ())?,
	OnBranchCreated: ((BranchName: string) -> ())?,
	OnBranchDeleted: ((BranchId: string) -> ())?,
	OnBranchRenamed: ((BranchId: string, NewName: string) -> ())?,
	OnSetEntry: ((BranchId: string) -> ())?,
}

export type BranchListInstance = {
	Frame: Frame,
	SetBranches: (Branches: { [string]: Types.BranchData }) -> (),
	SetSelectedBranch: (BranchId: string?) -> (),
	Destroy: () -> (),
}

function BranchList.Create(Config: BranchListConfig): BranchListInstance
	local Branches: { [string]: Types.BranchData } = {}
	local SelectedBranchId: string? = nil
	local BranchButtons: { [string]: { Frame: Frame, Connections: { RBXScriptConnection } } } = {}

	local Container = Panel.Create({
		Name = "BranchList",
		Size = UDim2.fromOffset(Theme.Sizes.PanelWidth, 200),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
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
	HeaderTitle.Size = UDim2.new(1, -48, 1, 0)
	HeaderTitle.Position = UDim2.fromOffset(8, 0)
	HeaderTitle.BackgroundTransparency = 1
	HeaderTitle.Text = "Branches"
	HeaderTitle.TextColor3 = Theme.Colors.Text
	HeaderTitle.FontFace = Theme.Fonts.Bold
	HeaderTitle.TextSize = Theme.TextSizes.Default
	HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
	HeaderTitle.Parent = Header

	local AddButton = Button.Create({
		Name = "Add",
		Text = "+",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -32, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor = Theme.Colors.Success,
		Parent = Header,
		OnClick = function()
			if Config.OnBranchCreated then
				Config.OnBranchCreated("NewBranch")
			end
		end,
	})

	local ContentScroll = Panel.CreateScrollable({
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -36),
		Position = UDim2.fromOffset(0, 36),
		BackgroundColor = Theme.Colors.Background,
		Padding = Theme.Sizes.PaddingSmall,
		Parent = Container,
	})

	Theme.ApplyListLayout(ContentScroll, Enum.FillDirection.Vertical, UDim.new(0, 2))

	local function ClearBranchButtons()
		for _, ButtonData in BranchButtons do
			for _, Connection in ButtonData.Connections do
				Connection:Disconnect()
			end
			ButtonData.Frame:Destroy()
		end
		table.clear(BranchButtons)
	end

	local function CreateBranchButton(BranchData: Types.BranchData, LayoutOrder: number)
		local BranchFrame = Instance.new("Frame")
		BranchFrame.Name = "Branch_" .. BranchData.BranchId
		BranchFrame.Size = UDim2.new(1, 0, 0, 32)
		BranchFrame.BackgroundColor3 = Theme.Colors.Surface
		BranchFrame.BorderSizePixel = 0
		BranchFrame.LayoutOrder = LayoutOrder
		BranchFrame.Parent = ContentScroll

		Theme.ApplyCorner(BranchFrame, Theme.Sizes.BorderRadiusSmall)
		local Stroke = Theme.ApplyStroke(BranchFrame, Theme.Colors.Border)

		if BranchData.IsEntry then
			local EntryIndicator = Instance.new("Frame")
			EntryIndicator.Name = "EntryIndicator"
			EntryIndicator.Size = UDim2.new(0, 4, 1, -4)
			EntryIndicator.Position = UDim2.fromOffset(2, 2)
			EntryIndicator.BackgroundColor3 = Theme.Colors.Success
			EntryIndicator.BorderSizePixel = 0
			EntryIndicator.Parent = BranchFrame
			Theme.ApplyCorner(EntryIndicator, UDim.new(0, 2))
		end

		local NameLabel = Instance.new("TextLabel")
		NameLabel.Name = "Name"
		NameLabel.Size = UDim2.new(1, -40, 1, 0)
		NameLabel.Position = UDim2.fromOffset(12, 0)
		NameLabel.BackgroundTransparency = 1
		NameLabel.Text = BranchData.BranchName
		NameLabel.TextColor3 = Theme.Colors.Text
		NameLabel.FontFace = Theme.Fonts.Default
		NameLabel.TextSize = Theme.TextSizes.Small
		NameLabel.TextXAlignment = Enum.TextXAlignment.Left
		NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		NameLabel.Parent = BranchFrame

		local ClickDetector = Instance.new("TextButton")
		ClickDetector.Name = "ClickDetector"
		ClickDetector.Size = UDim2.fromScale(1, 1)
		ClickDetector.BackgroundTransparency = 1
		ClickDetector.Text = ""
		ClickDetector.Parent = BranchFrame

		local Connections: { RBXScriptConnection } = {}

		table.insert(Connections, ClickDetector.MouseEnter:Connect(function()
			if SelectedBranchId ~= BranchData.BranchId then
				BranchFrame.BackgroundColor3 = Theme.Colors.SurfaceHover
			end
		end))

		table.insert(Connections, ClickDetector.MouseLeave:Connect(function()
			if SelectedBranchId ~= BranchData.BranchId then
				BranchFrame.BackgroundColor3 = Theme.Colors.Surface
			end
		end))

		table.insert(Connections, ClickDetector.MouseButton1Click:Connect(function()
			if Config.OnBranchSelected then
				Config.OnBranchSelected(BranchData.BranchId)
			end
		end))

		BranchButtons[BranchData.BranchId] = {
			Frame = BranchFrame,
			Connections = Connections,
		}

		if SelectedBranchId == BranchData.BranchId then
			BranchFrame.BackgroundColor3 = Theme.Colors.SurfaceActive
			Stroke.Color = Theme.Colors.BorderFocus
		end
	end

	local function RebuildList()
		ClearBranchButtons()

		local SortedBranches: { Types.BranchData } = {}
		for _, BranchData in Branches do
			table.insert(SortedBranches, BranchData)
		end

		table.sort(SortedBranches, function(BranchA, BranchB)
			if BranchA.IsEntry ~= BranchB.IsEntry then
				return BranchA.IsEntry
			end
			return BranchA.BranchName < BranchB.BranchName
		end)

		for Index, BranchData in SortedBranches do
			CreateBranchButton(BranchData, Index)
		end
	end

	local Instance: BranchListInstance = {
		Frame = Container,
	} :: any

	function Instance.SetBranches(NewBranches: { [string]: Types.BranchData })
		Branches = NewBranches
		RebuildList()
	end

	function Instance.SetSelectedBranch(BranchId: string?)
		local OldSelected = SelectedBranchId
		SelectedBranchId = BranchId

		if OldSelected and BranchButtons[OldSelected] then
			local OldButton = BranchButtons[OldSelected]
			OldButton.Frame.BackgroundColor3 = Theme.Colors.Surface
			local OldStroke = OldButton.Frame:FindFirstChildOfClass("UIStroke")
			if OldStroke then
				OldStroke.Color = Theme.Colors.Border
			end
		end

		if BranchId and BranchButtons[BranchId] then
			local NewButton = BranchButtons[BranchId]
			NewButton.Frame.BackgroundColor3 = Theme.Colors.SurfaceActive
			local NewStroke = NewButton.Frame:FindFirstChildOfClass("UIStroke")
			if NewStroke then
				NewStroke.Color = Theme.Colors.BorderFocus
			end
		end
	end

	function Instance.Destroy()
		ClearBranchButtons()
		AddButton.Destroy()
		Container:Destroy()
	end

	return Instance
end

return BranchList