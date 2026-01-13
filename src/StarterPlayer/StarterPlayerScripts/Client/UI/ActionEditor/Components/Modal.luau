--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
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
	Parent: Instance,
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

	local ModalParts = UILibrary.ModalContainer({
		ZIndex = Theme.ZIndex.Modal,
		Parent = Config.Parent,
	})

	local Overlay = ModalParts.Overlay
	local Dialog = ModalParts.Dialog
	local DialogScale = ModalParts.Scale

	UILibrary.Padding({
		All = UDim.new(0, 16),
		Parent = Dialog,
	})

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = Dialog,
	})

	local TitleLabel = UILibrary.HeaderLabel({
		Name = "Title",
		Text = Config.Title,
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	TitleLabel.LayoutOrder = 1

	if Config.Message then
		local MessageLabel = UILibrary.BodyLabel({
			Name = "Message",
			Text = Config.Message,
			Size = UDim2.fromScale(1, 0),
			ZIndex = Theme.ZIndex.Modal + 2,
			Parent = Dialog,
		})
		MessageLabel.TextColor3 = Theme.Colors.TextMuted
		MessageLabel.TextXAlignment = Enum.TextXAlignment.Center
		MessageLabel.LayoutOrder = 2
	end

	local ButtonContainer = UILibrary.TransparentContainer({
		Name = "Buttons",
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	ButtonContainer.LayoutOrder = 3

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = ButtonContainer,
	})

	local ModalInstance: ModalInstance = {
		Frame = Overlay,
	} :: any

	local function CloseModal()
		TweenService:Create(Overlay, FADE_TWEEN, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(DialogScale, FADE_TWEEN, { Scale = 0.9 }):Play()

		task.delay(0.15, function()
			if Config.OnClosed then
				Config.OnClosed()
			end
			ModalInstance.Destroy()
		end)
	end

	function ModalInstance.Close()
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

	function ModalInstance.Destroy()
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

	return ModalInstance
end

export type ConfirmConfig = {
	Title: string,
	Message: string,
	ConfirmText: string?,
	CancelText: string?,
	ConfirmColor: Color3?,
	Parent: Instance,
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
	Parent: Instance,
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

	local ModalParts = UILibrary.ModalContainer({
		Size = UDim2.fromOffset(320, 400),
		ZIndex = Theme.ZIndex.Modal,
		Parent = Config.Parent,
	})

	local Overlay = ModalParts.Overlay
	local Dialog = ModalParts.Dialog
	local DialogScale = ModalParts.Scale

	Dialog.AutomaticSize = Enum.AutomaticSize.None

	UILibrary.ModalHeader({
		Title = Config.Title,
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})

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

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		Parent = ContentScroll,
	})

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
		local EmptyLabel = UILibrary.BodyLabel({
			Name = "Empty",
			Text = "No items found",
			Size = UDim2.new(1, 0, 0, 40),
			ZIndex = Theme.ZIndex.Modal + 3,
			Parent = ContentScroll,
		})
		EmptyLabel.TextColor3 = Theme.Colors.TextMuted
		EmptyLabel.TextXAlignment = Enum.TextXAlignment.Center
	else
		for Index, Option in Config.Options do
			local OptionButton = UILibrary.ListItemButton({
				Name = "Option_" .. Option.Id,
				Text = Option.Name,
				Size = UDim2.new(1, 0, 0, 36),
				LayoutOrder = Index,
				ZIndex = Theme.ZIndex.Modal + 3,
				Parent = ContentScroll,
			})

			OptionButton.BackgroundColor3 = Theme.Colors.Background

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