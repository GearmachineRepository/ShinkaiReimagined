--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local Button = require(script.Parent.Button)

local TemplatesModal = {}

export type TemplateEntry = {
	ActionId: string,
	DisplayName: string,
	Description: string?,
}

export type TemplatesModalConfig = {
	Parent: Instance,
	Templates: { TemplateEntry },
	OnSelect: ((ActionId: string) -> ())?,
	OnClose: (() -> ())?,
}

export type TemplatesModalInstance = {
	Frame: Frame,
	Close: () -> (),
	Destroy: () -> (),
}

local FADE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SCALE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function TemplatesModal.Create(Config: TemplatesModalConfig): TemplatesModalInstance
	local Connections: { RBXScriptConnection } = {}

	local ModalParts = UILibrary.ModalContainer({
		Size = UDim2.fromOffset(400, 450),
		ZIndex = Theme.ZIndex.Modal,
		Parent = Config.Parent,
	})

	local Overlay = ModalParts.Overlay
	local Dialog = ModalParts.Dialog
	local DialogScale = ModalParts.Scale

	Dialog.AutomaticSize = Enum.AutomaticSize.None

	local TitleLabel = UILibrary.HeaderLabel({
		Name = "Title",
		Text = "Action Templates",
		Size = UDim2.new(1, 0, 0, 40),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Center

	local ListContainer = Instance.new("ScrollingFrame")
	ListContainer.Name = "List"
	ListContainer.Size = UDim2.new(1, -24, 1, -100)
	ListContainer.Position = UDim2.fromOffset(12, 44)
	ListContainer.BackgroundColor3 = Theme.Colors.BackgroundDark
	ListContainer.BorderSizePixel = 0
	ListContainer.ScrollBarThickness = 6
	ListContainer.ScrollBarImageColor3 = Theme.Colors.BorderLight
	ListContainer.CanvasSize = UDim2.fromScale(0, 0)
	ListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ListContainer.ZIndex = Theme.ZIndex.Modal + 2
	ListContainer.Parent = Dialog

	UILibrary.Corner(ListContainer, Theme.Sizes.BorderRadiusSmall)

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		Parent = ListContainer,
	})

	UILibrary.Padding({
		All = UDim.new(0, 4),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})

	local ModalInstance: TemplatesModalInstance = {
		Frame = Overlay,
	} :: any

	local function CloseModal()
		TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(DialogScale, FADE_TWEEN, { Scale = 0.9 }):Play()

		task.delay(0.15, function()
			if Config.OnClose then
				Config.OnClose()
			end
			ModalInstance.Destroy()
		end)
	end

	function ModalInstance.Close()
		CloseModal()
	end

	for Index, Template in Config.Templates do
		local ItemButton = UILibrary.ListItemButton({
			Name = Template.ActionId,
			Text = "",
			Size = UDim2.new(1, 0, 0, 50),
			LayoutOrder = Index,
			ZIndex = Theme.ZIndex.Modal + 3,
			Parent = ListContainer,
		})

		UILibrary.HeaderLabel({
			Name = "Name",
			Text = Template.DisplayName,
			Size = UDim2.new(1, -16, 0, 20),
			Position = UDim2.fromOffset(8, 6),
			ZIndex = Theme.ZIndex.Modal + 4,
			Parent = ItemButton,
		})

		local DescLabel = UILibrary.BodyLabel({
			Name = "Desc",
			Text = Template.Description or Template.ActionId,
			Size = UDim2.new(1, -16, 0, 16),
			Position = UDim2.fromOffset(8, 26),
			ZIndex = Theme.ZIndex.Modal + 4,
			Parent = ItemButton,
		})
		DescLabel.TextColor3 = Theme.Colors.TextMuted
		DescLabel.TextSize = Theme.TextSizes.Small
		DescLabel.TextTruncate = Enum.TextTruncate.AtEnd

		table.insert(Connections, ItemButton.MouseEnter:Connect(function()
			TweenService:Create(ItemButton, FADE_TWEEN, { BackgroundColor3 = Theme.Colors.SurfaceHover }):Play()
		end))

		table.insert(Connections, ItemButton.MouseLeave:Connect(function()
			TweenService:Create(ItemButton, FADE_TWEEN, { BackgroundColor3 = Theme.Colors.Surface }):Play()
		end))

		table.insert(Connections, ItemButton.MouseButton1Click:Connect(function()
			if Config.OnSelect then
				Config.OnSelect(Template.ActionId)
			end
			CloseModal()
		end))
	end

	local CloseButton = Button.Create({
		Name = "Close",
		Text = "Cancel",
		Size = UDim2.fromOffset(100, 32),
		BackgroundColor = Theme.Colors.Surface,
		ZIndex = Theme.ZIndex.Modal + 3,
		Parent = Dialog,
	})
	CloseButton.Frame.Position = UDim2.new(0.5, -50, 1, -44)

	table.insert(Connections, CloseButton.Frame.MouseButton1Click:Connect(function()
		CloseModal()
	end))

	table.insert(Connections, Overlay.MouseButton1Click:Connect(function()
		CloseModal()
	end))

	TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(DialogScale, SCALE_TWEEN, { Scale = 1 }):Play()

	function ModalInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		CloseButton.Destroy()
		Overlay:Destroy()
	end

	return ModalInstance
end

return TemplatesModal