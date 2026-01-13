--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local Button = require(script.Parent.Button)

local ExportJsonModal = {}

export type ExportJsonModalConfig = {
	Parent: Instance,
	JsonContent: string,
	OnClose: (() -> ())?,
}

export type ExportJsonModalInstance = {
	Frame: Frame,
	Close: () -> (),
	Destroy: () -> (),
}

local FADE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SCALE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

function ExportJsonModal.Create(Config: ExportJsonModalConfig): ExportJsonModalInstance
	local Connections: { RBXScriptConnection } = {}

	local ModalParts = UILibrary.ModalContainer({
		Size = UDim2.fromOffset(600, 500),
		ZIndex = Theme.ZIndex.Modal,
		Parent = Config.Parent,
	})

	local Overlay = ModalParts.Overlay
	local Dialog = ModalParts.Dialog
	local DialogScale = ModalParts.Scale

	Dialog.AutomaticSize = Enum.AutomaticSize.None

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
		Text = "Export JSON",
		Size = UDim2.new(1, 0, 0, 24),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	TitleLabel.LayoutOrder = 1

	local HintLabel = UILibrary.BodyLabel({
		Name = "Hint",
		Text = "Select all (Ctrl+A) and copy (Ctrl+C)",
		Size = UDim2.new(1, 0, 0, 20),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	HintLabel.TextColor3 = Theme.Colors.TextMuted
	HintLabel.TextSize = Theme.TextSizes.Small
	HintLabel.TextXAlignment = Enum.TextXAlignment.Center
	HintLabel.LayoutOrder = 2

	local TextBoxScroll = UILibrary.DarkScrollContainer({
		Name = "TextBoxScroll",
		Size = UDim2.new(1, 0, 1, -120),
		ZIndex = Theme.ZIndex.Modal + 2,
		Parent = Dialog,
	})
	TextBoxScroll.LayoutOrder = 3
	TextBoxScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local JsonTextBox = Instance.new("TextBox")
	JsonTextBox.Name = "JsonContent"
	JsonTextBox.Size = UDim2.new(1, -16, 0, 0)
	JsonTextBox.Position = UDim2.fromOffset(8, 8)
	JsonTextBox.AutomaticSize = Enum.AutomaticSize.Y
	JsonTextBox.BackgroundTransparency = 1
	JsonTextBox.Text = Config.JsonContent
	JsonTextBox.TextColor3 = Theme.Colors.Text
	JsonTextBox.FontFace = Theme.Fonts.Mono
	JsonTextBox.TextSize = Theme.TextSizes.Small
	JsonTextBox.TextXAlignment = Enum.TextXAlignment.Left
	JsonTextBox.TextYAlignment = Enum.TextYAlignment.Top
	JsonTextBox.TextWrapped = true
	JsonTextBox.ClearTextOnFocus = false
	JsonTextBox.TextEditable = false
	JsonTextBox.MultiLine = true
	JsonTextBox.ZIndex = Theme.ZIndex.Modal + 3
	JsonTextBox.Parent = TextBoxScroll

	local CloseButton = Button.Create({
		Name = "Close",
		Text = "Close",
		Size = UDim2.fromOffset(120, 36),
		BackgroundColor = Theme.Colors.Primary,
		ZIndex = Theme.ZIndex.Modal + 3,
		Parent = Dialog,
	})
	CloseButton.Frame.LayoutOrder = 4

	local ModalInstance: ExportJsonModalInstance = {
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

return ExportJsonModal