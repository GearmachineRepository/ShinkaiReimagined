--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Button)

local TemplatesModal = {}

export type TemplateEntry = {
	ActionId: string,
	DisplayName: string,
	Description: string?,
}

export type TemplatesModalConfig = {
	Parent: GuiObject,
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

	local Overlay = Instance.new("TextButton")
	Overlay.Name = "TemplatesOverlay"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 1
	Overlay.BorderSizePixel = 0
	Overlay.Text = ""
	Overlay.AutoButtonColor = false
	Overlay.ZIndex = Theme.ZIndex.Modal
	Overlay.Parent = Config.Parent

	local Dialog = Instance.new("Frame")
	Dialog.Name = "Dialog"
	Dialog.Size = UDim2.fromOffset(400, 450)
	Dialog.Position = UDim2.fromScale(0.5, 0.5)
	Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	Dialog.BackgroundColor3 = Theme.Colors.Surface
	Dialog.BorderSizePixel = 0
	Dialog.ZIndex = Theme.ZIndex.Modal + 1
	Dialog.Parent = Overlay

	Theme.ApplyCorner(Dialog, Theme.Sizes.BorderRadius)
	Theme.ApplyStroke(Dialog, Theme.Colors.Border)

	local DialogScale = Instance.new("UIScale")
	DialogScale.Scale = 0.9
	DialogScale.Parent = Dialog

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, 0, 0, 40)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = "Action Templates"
	TitleLabel.TextColor3 = Theme.Colors.Text
	TitleLabel.FontFace = Theme.Fonts.Bold
	TitleLabel.TextSize = Theme.TextSizes.Large
	TitleLabel.ZIndex = Theme.ZIndex.Modal + 2
	TitleLabel.Parent = Dialog

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

	Theme.ApplyCorner(ListContainer, Theme.Sizes.BorderRadiusSmall)

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.FillDirection = Enum.FillDirection.Vertical
	ListLayout.Padding = UDim.new(0, 4)
	ListLayout.Parent = ListContainer

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingTop = UDim.new(0, 4)
	ListPadding.PaddingBottom = UDim.new(0, 4)
	ListPadding.PaddingLeft = UDim.new(0, 4)
	ListPadding.PaddingRight = UDim.new(0, 4)
	ListPadding.Parent = ListContainer

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
		local ItemButton = Instance.new("TextButton")
		ItemButton.Name = Template.ActionId
		ItemButton.Size = UDim2.new(1, 0, 0, 50)
		ItemButton.BackgroundColor3 = Theme.Colors.Surface
		ItemButton.BorderSizePixel = 0
		ItemButton.Text = ""
		ItemButton.AutoButtonColor = false
		ItemButton.LayoutOrder = Index
		ItemButton.ZIndex = Theme.ZIndex.Modal + 3
		ItemButton.Parent = ListContainer

		Theme.ApplyCorner(ItemButton, Theme.Sizes.BorderRadiusSmall)

		local NameLabel = Instance.new("TextLabel")
		NameLabel.Name = "Name"
		NameLabel.Size = UDim2.new(1, -16, 0, 20)
		NameLabel.Position = UDim2.fromOffset(8, 6)
		NameLabel.BackgroundTransparency = 1
		NameLabel.Text = Template.DisplayName
		NameLabel.TextColor3 = Theme.Colors.Text
		NameLabel.FontFace = Theme.Fonts.Bold
		NameLabel.TextSize = Theme.TextSizes.Default
		NameLabel.TextXAlignment = Enum.TextXAlignment.Left
		NameLabel.ZIndex = Theme.ZIndex.Modal + 4
		NameLabel.Parent = ItemButton

		local DescLabel = Instance.new("TextLabel")
		DescLabel.Name = "Desc"
		DescLabel.Size = UDim2.new(1, -16, 0, 16)
		DescLabel.Position = UDim2.fromOffset(8, 26)
		DescLabel.BackgroundTransparency = 1
		DescLabel.Text = Template.Description or Template.ActionId
		DescLabel.TextColor3 = Theme.Colors.TextMuted
		DescLabel.FontFace = Theme.Fonts.Default
		DescLabel.TextSize = Theme.TextSizes.Small
		DescLabel.TextXAlignment = Enum.TextXAlignment.Left
		DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
		DescLabel.ZIndex = Theme.ZIndex.Modal + 4
		DescLabel.Parent = ItemButton

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