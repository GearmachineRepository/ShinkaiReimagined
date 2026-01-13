--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local UILibrary = require(script.Parent.Parent.UILibrary)
local Panel = require(script.Parent.Parent.Components.Panel)

local BranchList = {}

export type BranchListConfig = {
	Parent: Instance?,
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
		Text = "Branches",
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		ZIndex = Theme.ZIndex.Panel,
		Parent = Header,
	})

	local AddButton = UILibrary.IconButton({
		Name = "AddButton",
		Icon = "+",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -32, 0.5, 0),
		ZIndex = Theme.ZIndex.Panel + 1,
		Parent = Header,
	})
	AddButton.AnchorPoint = Vector2.new(0, 0.5)
	AddButton.BackgroundColor3 = Theme.Colors.Success

	AddButton.MouseEnter:Connect(function()
		AddButton.BackgroundColor3 = Color3.fromRGB(100, 200, 140)
	end)

	AddButton.MouseLeave:Connect(function()
		AddButton.BackgroundColor3 = Theme.Colors.Success
	end)

	AddButton.MouseButton1Click:Connect(function()
		if Config.OnBranchCreated then
			Config.OnBranchCreated("NewBranch")
		end
	end)

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
		Padding = UDim.new(0, 2),
		Parent = ContentScroll,
	})

	local function ClearBranchButtons()
		for _, ButtonData in BranchButtons do
			for _, Connection in ButtonData.Connections do
				Connection:Disconnect()
			end
			ButtonData.Frame:Destroy()
		end
		table.clear(BranchButtons)
	end

	local function RebuildBranchList()
		ClearBranchButtons()

		local LayoutOrder = 0
		for BranchId, BranchData in Branches do
			LayoutOrder = LayoutOrder + 1

			local BranchFrame = UILibrary.SurfaceContainer({
				Name = "Branch_" .. BranchId,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = LayoutOrder,
				ZIndex = Theme.ZIndex.Panel,
				Parent = ContentScroll,
			})
			BranchFrame.BackgroundColor3 = if BranchId == SelectedBranchId
				then Theme.Colors.SurfaceActive
				else Theme.Colors.Surface

			local FrameStroke = BranchFrame:FindFirstChildOfClass("UIStroke")
			if FrameStroke then
				FrameStroke:Destroy()
			end

			local EntryIndicator = UILibrary.TransparentContainer({
				Name = "EntryIndicator",
				Size = UDim2.new(0, 4, 1, -4),
				Position = UDim2.fromOffset(2, 2),
				ZIndex = Theme.ZIndex.Panel,
				Parent = BranchFrame,
			})
			EntryIndicator.BackgroundTransparency = 0
			EntryIndicator.BackgroundColor3 = if BranchData.IsEntry
				then Theme.Colors.Success
				else Theme.Colors.TextDisabled
			UILibrary.Corner(EntryIndicator, UDim.new(0, 2))

			local BranchLabel = UILibrary.PropertyLabel({
				Name = "Label",
				Text = BranchData.BranchName,
				Size = UDim2.new(1, -48, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				ZIndex = Theme.ZIndex.Panel,
				Parent = BranchFrame,
			})
			BranchLabel.TextColor3 = Theme.Colors.Text
			BranchLabel.TextTruncate = Enum.TextTruncate.AtEnd

			local RenameInput = Instance.new("TextBox")
			RenameInput.Name = "RenameInput"
			RenameInput.Size = UDim2.new(1, -48, 1, -4)
			RenameInput.Position = UDim2.fromOffset(12, 2)
			RenameInput.BackgroundColor3 = Theme.Colors.BackgroundDark
			RenameInput.Text = BranchData.BranchName
			RenameInput.TextColor3 = Theme.Colors.Text
			RenameInput.FontFace = Theme.Fonts.Default
			RenameInput.TextSize = Theme.TextSizes.Small
			RenameInput.TextXAlignment = Enum.TextXAlignment.Left
			RenameInput.ClearTextOnFocus = false
			RenameInput.Visible = false
			RenameInput.ZIndex = Theme.ZIndex.Panel + 1
			RenameInput.Parent = BranchFrame
			UILibrary.Corner(RenameInput, Theme.Sizes.BorderRadiusSmall)

			local DeleteButton = UILibrary.IconButton({
				Name = "Delete",
				Icon = "×",
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(1, -24, 0.5, 0),
				ZIndex = Theme.ZIndex.Panel + 1,
				Parent = BranchFrame,
			})
			DeleteButton.AnchorPoint = Vector2.new(0, 0.5)
			DeleteButton.BackgroundColor3 = Theme.Colors.Error

			local ClickDetector = UILibrary.ClickBlocker({
				Name = "ClickDetector",
				ZIndex = Theme.ZIndex.Panel,
				Parent = BranchFrame,
			})
			ClickDetector.Size = UDim2.new(1, -30, 1, 0)
			ClickDetector.Position = UDim2.fromOffset(0, 0)

			local Connections: { RBXScriptConnection } = {}
			local LastClickTime = 0

			table.insert(Connections, ClickDetector.MouseButton1Click:Connect(function()
				local CurrentTime = tick()
				local TimeSinceLastClick = CurrentTime - LastClickTime
				LastClickTime = CurrentTime

				if TimeSinceLastClick < 0.3 then
					BranchLabel.Visible = false
					RenameInput.Visible = true
					RenameInput.Text = BranchData.BranchName
					RenameInput:CaptureFocus()
				else
					if Config.OnBranchSelected then
						Config.OnBranchSelected(BranchId)
					end
				end
			end))

			table.insert(Connections, RenameInput.FocusLost:Connect(function(_EnterPressed: boolean)
				RenameInput.Visible = false
				BranchLabel.Visible = true

				local NewName = RenameInput.Text
				if NewName ~= "" and NewName ~= BranchData.BranchName then
					BranchLabel.Text = NewName
					if Config.OnBranchRenamed then
						Config.OnBranchRenamed(BranchId, NewName)
					end
				end
			end))

			table.insert(Connections, ClickDetector.MouseEnter:Connect(function()
				if BranchId ~= SelectedBranchId then
					BranchFrame.BackgroundColor3 = Theme.Colors.SurfaceHover
				end
			end))

			table.insert(Connections, ClickDetector.MouseLeave:Connect(function()
				if BranchId ~= SelectedBranchId then
					BranchFrame.BackgroundColor3 = Theme.Colors.Surface
				end
			end))

			table.insert(Connections, DeleteButton.MouseButton1Click:Connect(function()
				if Config.OnBranchDeleted then
					Config.OnBranchDeleted(BranchId)
				end
			end))

			table.insert(Connections, DeleteButton.MouseEnter:Connect(function()
				DeleteButton.BackgroundColor3 = Theme.Colors.Warning
			end))

			table.insert(Connections, DeleteButton.MouseLeave:Connect(function()
				DeleteButton.BackgroundColor3 = Theme.Colors.Error
			end))

			BranchButtons[BranchId] = {
				Frame = BranchFrame,
				Connections = Connections,
			}
		end
	end

	local BranchListInstance: BranchListInstance = {
		Frame = Container,
	} :: any

	function BranchListInstance.SetBranches(NewBranches: { [string]: Types.BranchData })
		Branches = NewBranches
		RebuildBranchList()
	end

	function BranchListInstance.SetSelectedBranch(BranchId: string?)
		local OldSelected = SelectedBranchId
		SelectedBranchId = BranchId

		if OldSelected and BranchButtons[OldSelected] then
			BranchButtons[OldSelected].Frame.BackgroundColor3 = Theme.Colors.Surface
		end

		if BranchId and BranchButtons[BranchId] then
			BranchButtons[BranchId].Frame.BackgroundColor3 = Theme.Colors.SurfaceActive
		end
	end

	function BranchListInstance.Destroy()
		ClearBranchButtons()
		Container:Destroy()
	end

	return BranchListInstance
end

return BranchList