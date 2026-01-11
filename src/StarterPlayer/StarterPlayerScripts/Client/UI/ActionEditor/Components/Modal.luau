--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Button)

local Modal = {}

local FADE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SCALE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

export type ModalButton = {
	Text: string,
	Color: Color3?,
	Callback: () -> (),
}

export type ModalConfig = {
	Title: string,
	Message: string?,
	Buttons: { ModalButton },
	Parent: GuiObject,
	OnClosed: (() -> ())?,
}

export type ModalInstance = {
	Frame: Frame,
	Close: () -> (),
	Destroy: () -> (),
}

function Modal.Create(Config: ModalConfig): ModalInstance
	local Connections: { RBXScriptConnection } = {}
	local ButtonInstances: { Button.ButtonInstance } = {}

	local Overlay = Instance.new("TextButton")
	Overlay.Name = "ModalOverlay"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Theme.Colors.Overlay
	Overlay.BackgroundTransparency = 1
	Overlay.Text = ""
	Overlay.AutoButtonColor = false
	Overlay.ZIndex = Theme.ZIndex.Modal
	Overlay.Parent = Config.Parent

	local Dialog = Instance.new("Frame")
	Dialog.Name = "ModalDialog"
	Dialog.Size = UDim2.fromOffset(360, 0)
	Dialog.Position = UDim2.fromScale(0.5, 0.5)
	Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	Dialog.BackgroundColor3 = Theme.Colors.Surface
	Dialog.BorderSizePixel = 0
	Dialog.AutomaticSize = Enum.AutomaticSize.Y
	Dialog.ZIndex = Theme.ZIndex.Modal + 1
	Dialog.Parent = Overlay

	Theme.ApplyCorner(Dialog, Theme.Sizes.BorderRadiusLarge)
	Theme.ApplyStroke(Dialog, Theme.Colors.Border)

	local DialogScale = Instance.new("UIScale")
	DialogScale.Scale = 0.9
	DialogScale.Parent = Dialog

	local ContentPadding = Instance.new("UIPadding")
	ContentPadding.PaddingTop = UDim.new(0, 16)
	ContentPadding.PaddingBottom = UDim.new(0, 16)
	ContentPadding.PaddingLeft = UDim.new(0, 16)
	ContentPadding.PaddingRight = UDim.new(0, 16)
	ContentPadding.Parent = Dialog

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.FillDirection = Enum.FillDirection.Vertical
	ContentLayout.Padding = UDim.new(0, 12)
	ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ContentLayout.Parent = Dialog

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, 0, 0, 24)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = Config.Title
	TitleLabel.TextColor3 = Theme.Colors.Text
	TitleLabel.FontFace = Theme.Fonts.Bold
	TitleLabel.TextSize = Theme.TextSizes.Large
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	TitleLabel.LayoutOrder = 1
	TitleLabel.ZIndex = Theme.ZIndex.Modal + 2
	TitleLabel.Parent = Dialog

	if Config.Message then
		local MessageLabel = Instance.new("TextLabel")
		MessageLabel.Name = "Message"
		MessageLabel.Size = UDim2.fromScale(1, 0)
		MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
		MessageLabel.BackgroundTransparency = 1
		MessageLabel.Text = Config.Message
		MessageLabel.TextColor3 = Theme.Colors.TextMuted
		MessageLabel.FontFace = Theme.Fonts.Default
		MessageLabel.TextSize = Theme.TextSizes.Default
		MessageLabel.TextXAlignment = Enum.TextXAlignment.Center
		MessageLabel.TextWrapped = true
		MessageLabel.LayoutOrder = 2
		MessageLabel.ZIndex = Theme.ZIndex.Modal + 2
		MessageLabel.Parent = Dialog
	end

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Name = "Buttons"
	ButtonContainer.Size = UDim2.new(1, 0, 0, 36)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.LayoutOrder = 3
	ButtonContainer.ZIndex = Theme.ZIndex.Modal + 2
	ButtonContainer.Parent = Dialog

	local ButtonLayout = Instance.new("UIListLayout")
	ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	ButtonLayout.Padding = UDim.new(0, 8)
	ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ButtonLayout.Parent = ButtonContainer

	local Instance: ModalInstance = {
		Frame = Overlay,
	} :: any

	local function CloseModal()
		TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(DialogScale, FADE_TWEEN, { Scale = 0.9 }):Play()

		task.delay(0.15, function()
			if Config.OnClosed then
				Config.OnClosed()
			end
			Instance.Destroy()
		end)
	end

	function Instance.Close()
		CloseModal()
	end

	for Index, ButtonConfig in Config.Buttons do
		local ButtonWidth = math.floor((360 - 32 - (8 * (#Config.Buttons - 1))) / #Config.Buttons)

		local ButtonInst = Button.Create({
			Name = "Button_" .. Index,
			Text = ButtonConfig.Text,
			Size = UDim2.fromOffset(ButtonWidth, 36),
			BackgroundColor = ButtonConfig.Color or Theme.Colors.Surface,
			ZIndex = Theme.ZIndex.Modal + 3,
			Parent = ButtonContainer,
			OnClick = function()
				CloseModal()
				ButtonConfig.Callback()
			end,
		})
		ButtonInst.Frame.LayoutOrder = Index
		table.insert(ButtonInstances, ButtonInst)
	end

	table.insert(Connections, Overlay.MouseButton1Click:Connect(function()
		CloseModal()
	end))

	TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(DialogScale, SCALE_TWEEN, { Scale = 1 }):Play()

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)

		for _, ButtonInst in ButtonInstances do
			ButtonInst.Destroy()
		end
		table.clear(ButtonInstances)

		Overlay:Destroy()
	end

	return Instance
end

export type ConfirmConfig = {
	Title: string,
	Message: string,
	ConfirmText: string?,
	CancelText: string?,
	ConfirmColor: Color3?,
	Parent: GuiObject,
	OnConfirm: () -> (),
	OnCancel: (() -> ())?,
}

function Modal.Confirm(Config: ConfirmConfig): ModalInstance
	return Modal.Create({
		Title = Config.Title,
		Message = Config.Message,
		Parent = Config.Parent,
		Buttons = {
			{
				Text = Config.CancelText or "Cancel",
				Color = Theme.Colors.Surface,
				Callback = function()
					if Config.OnCancel then
						Config.OnCancel()
					end
				end,
			},
			{
				Text = Config.ConfirmText or "Confirm",
				Color = Config.ConfirmColor or Theme.Colors.Primary,
				Callback = Config.OnConfirm,
			},
		},
	})
end

export type SelectConfig = {
	Title: string,
	Options: { { Id: string, Name: string } },
	Parent: GuiObject,
	OnSelected: (Id: string) -> (),
	OnCancelled: (() -> ())?,
}

export type SelectModalInstance = {
	Frame: Frame,
	Close: () -> (),
	Destroy: () -> (),
}

function Modal.Select(Config: SelectConfig): SelectModalInstance
	local Connections: { RBXScriptConnection } = {}

	local Overlay = Instance.new("TextButton")
	Overlay.Name = "ModalOverlay"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Theme.Colors.Overlay
	Overlay.BackgroundTransparency = 1
	Overlay.Text = ""
	Overlay.AutoButtonColor = false
	Overlay.ZIndex = Theme.ZIndex.Modal
	Overlay.Parent = Config.Parent

	local Dialog = Instance.new("Frame")
	Dialog.Name = "SelectDialog"
	Dialog.Size = UDim2.fromOffset(320, 400)
	Dialog.Position = UDim2.fromScale(0.5, 0.5)
	Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	Dialog.BackgroundColor3 = Theme.Colors.Surface
	Dialog.BorderSizePixel = 0
	Dialog.ZIndex = Theme.ZIndex.Modal + 1
	Dialog.Parent = Overlay

	Theme.ApplyCorner(Dialog, Theme.Sizes.BorderRadiusLarge)
	Theme.ApplyStroke(Dialog, Theme.Colors.Border)

	local DialogScale = Instance.new("UIScale")
	DialogScale.Scale = 0.9
	DialogScale.Parent = Dialog

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 48)
	Header.BackgroundColor3 = Theme.Colors.BackgroundDark
	Header.BorderSizePixel = 0
	Header.ZIndex = Theme.ZIndex.Modal + 2
	Header.Parent = Dialog

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = Theme.Sizes.BorderRadiusLarge
	HeaderCorner.Parent = Header

	local HeaderMask = Instance.new("Frame")
	HeaderMask.Name = "Mask"
	HeaderMask.Size = UDim2.new(1, 0, 0, 12)
	HeaderMask.Position = UDim2.new(0, 0, 1, -12)
	HeaderMask.BackgroundColor3 = Theme.Colors.BackgroundDark
	HeaderMask.BorderSizePixel = 0
	HeaderMask.ZIndex = Theme.ZIndex.Modal + 2
	HeaderMask.Parent = Header

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, -16, 1, 0)
	TitleLabel.Position = UDim2.fromOffset(16, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = Config.Title
	TitleLabel.TextColor3 = Theme.Colors.Text
	TitleLabel.FontFace = Theme.Fonts.Bold
	TitleLabel.TextSize = Theme.TextSizes.Large
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = Theme.ZIndex.Modal + 3
	TitleLabel.Parent = Header

	local ContentScroll = Instance.new("ScrollingFrame")
	ContentScroll.Name = "Content"
	ContentScroll.Size = UDim2.new(1, -16, 1, -56)
	ContentScroll.Position = UDim2.fromOffset(8, 48)
	ContentScroll.BackgroundTransparency = 1
	ContentScroll.BorderSizePixel = 0
	ContentScroll.ScrollBarThickness = 4
	ContentScroll.ScrollBarImageColor3 = Theme.Colors.TextMuted
	ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ContentScroll.CanvasSize = UDim2.fromScale(0, 0)
	ContentScroll.ZIndex = Theme.ZIndex.Modal + 2
	ContentScroll.Parent = Dialog

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.FillDirection = Enum.FillDirection.Vertical
	ContentLayout.Padding = UDim.new(0, 4)
	ContentLayout.Parent = ContentScroll

	local ModalInstance: SelectModalInstance = {
		Frame = Overlay,
	} :: any

	local function CloseModal()
		TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(DialogScale, FADE_TWEEN, { Scale = 0.9 }):Play()

		task.delay(0.15, function()
			ModalInstance.Destroy()
		end)
	end

	function ModalInstance.Close()
		CloseModal()
	end

	if #Config.Options == 0 then
		local EmptyLabel = Instance.new("TextLabel")
		EmptyLabel.Name = "Empty"
		EmptyLabel.Size = UDim2.new(1, 0, 0, 40)
		EmptyLabel.BackgroundTransparency = 1
		EmptyLabel.Text = "No items found"
		EmptyLabel.TextColor3 = Theme.Colors.TextMuted
		EmptyLabel.FontFace = Theme.Fonts.Default
		EmptyLabel.TextSize = Theme.TextSizes.Default
		EmptyLabel.ZIndex = Theme.ZIndex.Modal + 3
		EmptyLabel.Parent = ContentScroll
	else
		for Index, Option in Config.Options do
			local OptionButton = Instance.new("TextButton")
			OptionButton.Name = "Option_" .. Option.Id
			OptionButton.Size = UDim2.new(1, 0, 0, 36)
			OptionButton.BackgroundColor3 = Theme.Colors.Background
			OptionButton.BorderSizePixel = 0
			OptionButton.Text = Option.Name
			OptionButton.TextColor3 = Theme.Colors.Text
			OptionButton.FontFace = Theme.Fonts.Default
			OptionButton.TextSize = Theme.TextSizes.Default
			OptionButton.AutoButtonColor = false
			OptionButton.LayoutOrder = Index
			OptionButton.ZIndex = Theme.ZIndex.Modal + 3
			OptionButton.Parent = ContentScroll

			Theme.ApplyCorner(OptionButton, Theme.Sizes.BorderRadiusSmall)

			table.insert(Connections, OptionButton.MouseEnter:Connect(function()
				OptionButton.BackgroundColor3 = Theme.Colors.SurfaceHover
			end))

			table.insert(Connections, OptionButton.MouseLeave:Connect(function()
				OptionButton.BackgroundColor3 = Theme.Colors.Background
			end))

			table.insert(Connections, OptionButton.MouseButton1Click:Connect(function()
				CloseModal()
				Config.OnSelected(Option.Id)
			end))
		end
	end

	table.insert(Connections, Overlay.MouseButton1Click:Connect(function()
		if Config.OnCancelled then
			Config.OnCancelled()
		end
		CloseModal()
	end))

	TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(DialogScale, SCALE_TWEEN, { Scale = 1 }):Play()

	function ModalInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Overlay:Destroy()
	end

	return ModalInstance
end

return Modal