--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Panel = require(script.Parent.Parent.Components.Panel)

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
	HeaderTitle.Size = UDim2.new(1, -48, 1, 0)
	HeaderTitle.Position = UDim2.fromOffset(8, 0)
	HeaderTitle.BackgroundTransparency = 1
	HeaderTitle.Text = "Branches"
	HeaderTitle.TextColor3 = Theme.Colors.Text
	HeaderTitle.FontFace = Theme.Fonts.Bold
	HeaderTitle.TextSize = Theme.TextSizes.Default
	HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
	HeaderTitle.ZIndex = Theme.ZIndex.Panel
	HeaderTitle.Parent = Header

	local AddButton = Instance.new("TextButton")
	AddButton.Name = "AddButton"
	AddButton.Size = UDim2.fromOffset(28, 28)
	AddButton.Position = UDim2.new(1, -32, 0.5, 0)
	AddButton.AnchorPoint = Vector2.new(0, 0.5)
	AddButton.BackgroundColor3 = Theme.Colors.Success
	AddButton.BorderSizePixel = 0
	AddButton.Text = "+"
	AddButton.TextColor3 = Theme.Colors.Text
	AddButton.FontFace = Theme.Fonts.Bold
	AddButton.TextSize = Theme.TextSizes.Large
	AddButton.AutoButtonColor = false
	AddButton.ZIndex = Theme.ZIndex.Panel + 1
	AddButton.Parent = Header

	Theme.ApplyCorner(AddButton, Theme.Sizes.BorderRadiusSmall)

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

	local function RebuildBranchList()
		ClearBranchButtons()

		local LayoutOrder = 0
		for BranchId, BranchData in Branches do
			LayoutOrder = LayoutOrder + 1

			local BranchFrame = Instance.new("Frame")
			BranchFrame.Name = "Branch_" .. BranchId
			BranchFrame.Size = UDim2.new(1, 0, 0, 32)
			BranchFrame.BackgroundColor3 = if BranchId == SelectedBranchId
				then Theme.Colors.SurfaceActive
				else Theme.Colors.Surface
			BranchFrame.BorderSizePixel = 0
			BranchFrame.LayoutOrder = LayoutOrder
			BranchFrame.ZIndex = Theme.ZIndex.Panel
			BranchFrame.Parent = ContentScroll

			Theme.ApplyCorner(BranchFrame, Theme.Sizes.BorderRadiusSmall)

			local EntryIndicator = Instance.new("Frame")
			EntryIndicator.Name = "EntryIndicator"
			EntryIndicator.Size = UDim2.new(0, 4, 1, -4)
			EntryIndicator.Position = UDim2.fromOffset(2, 2)
			EntryIndicator.BackgroundColor3 = if BranchData.IsEntry
				then Theme.Colors.Success
				else Theme.Colors.TextDisabled
			EntryIndicator.BorderSizePixel = 0
			EntryIndicator.ZIndex = Theme.ZIndex.Panel
			EntryIndicator.Parent = BranchFrame

			Theme.ApplyCorner(EntryIndicator, UDim.new(0, 2))

			local BranchLabel = Instance.new("TextLabel")
			BranchLabel.Name = "Label"
			BranchLabel.Size = UDim2.new(1, -48, 1, 0)
			BranchLabel.Position = UDim2.fromOffset(12, 0)
			BranchLabel.BackgroundTransparency = 1
			BranchLabel.Text = BranchData.BranchName
			BranchLabel.TextColor3 = Theme.Colors.Text
			BranchLabel.FontFace = Theme.Fonts.Default
			BranchLabel.TextSize = Theme.TextSizes.Small
			BranchLabel.TextXAlignment = Enum.TextXAlignment.Left
			BranchLabel.TextTruncate = Enum.TextTruncate.AtEnd
			BranchLabel.ZIndex = Theme.ZIndex.Panel
			BranchLabel.Parent = BranchFrame

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

			Theme.ApplyCorner(RenameInput, Theme.Sizes.BorderRadiusSmall)

			local DeleteButton = Instance.new("TextButton")
			DeleteButton.Name = "Delete"
			DeleteButton.Size = UDim2.fromOffset(20, 20)
			DeleteButton.Position = UDim2.new(1, -24, 0.5, 0)
			DeleteButton.AnchorPoint = Vector2.new(0, 0.5)
			DeleteButton.BackgroundColor3 = Theme.Colors.Error
			DeleteButton.BorderSizePixel = 0
			DeleteButton.Text = "×"
			DeleteButton.TextColor3 = Theme.Colors.Text
			DeleteButton.FontFace = Theme.Fonts.Bold
			DeleteButton.TextSize = Theme.TextSizes.Default
			DeleteButton.AutoButtonColor = false
			DeleteButton.ZIndex = Theme.ZIndex.Panel + 1
			DeleteButton.Parent = BranchFrame

			Theme.ApplyCorner(DeleteButton, Theme.Sizes.BorderRadiusSmall)

			local ClickDetector = Instance.new("TextButton")
			ClickDetector.Name = "ClickDetector"
			ClickDetector.Size = UDim2.new(1, -30, 1, 0)
			ClickDetector.Position = UDim2.fromOffset(0, 0)
			ClickDetector.BackgroundTransparency = 1
			ClickDetector.Text = ""
			ClickDetector.ZIndex = Theme.ZIndex.Panel
			ClickDetector.Parent = BranchFrame

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

	local Instance: BranchListInstance = {
		Frame = Container,
	} :: any

	function Instance.SetBranches(NewBranches: { [string]: Types.BranchData })
		Branches = NewBranches
		RebuildBranchList()
	end

	function Instance.SetSelectedBranch(BranchId: string?)
		local OldSelected = SelectedBranchId
		SelectedBranchId = BranchId

		if OldSelected and BranchButtons[OldSelected] then
			BranchButtons[OldSelected].Frame.BackgroundColor3 = Theme.Colors.Surface
		end

		if BranchId and BranchButtons[BranchId] then
			BranchButtons[BranchId].Frame.BackgroundColor3 = Theme.Colors.SurfaceActive
		end
	end

	function Instance.Destroy()
		ClearBranchButtons()
		Container:Destroy()
	end

	return Instance
end

return BranchList