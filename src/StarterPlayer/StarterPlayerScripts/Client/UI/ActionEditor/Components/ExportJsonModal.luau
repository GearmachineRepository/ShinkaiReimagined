--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Button = require(script.Parent.Button)

local ExportJsonModal = {}

export type ExportJsonModalConfig = {
	Parent: GuiObject,
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

	local Overlay = Instance.new("TextButton")
	Overlay.Name = "ExportJsonOverlay"
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
	Dialog.Size = UDim2.fromOffset(600, 500)
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

	local DialogLayout = Instance.new("UIListLayout")
	DialogLayout.FillDirection = Enum.FillDirection.Vertical
	DialogLayout.Padding = UDim.new(0, 12)
	DialogLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	DialogLayout.Parent = Dialog

	local DialogPadding = Instance.new("UIPadding")
	DialogPadding.PaddingTop = UDim.new(0, 16)
	DialogPadding.PaddingBottom = UDim.new(0, 16)
	DialogPadding.PaddingLeft = UDim.new(0, 16)
	DialogPadding.PaddingRight = UDim.new(0, 16)
	DialogPadding.Parent = Dialog

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Size = UDim2.new(1, 0, 0, 24)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text = "Export JSON"
	TitleLabel.TextColor3 = Theme.Colors.Text
	TitleLabel.FontFace = Theme.Fonts.Bold
	TitleLabel.TextSize = Theme.TextSizes.Large
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
	TitleLabel.LayoutOrder = 1
	TitleLabel.ZIndex = Theme.ZIndex.Modal + 2
	TitleLabel.Parent = Dialog

	local HintLabel = Instance.new("TextLabel")
	HintLabel.Name = "Hint"
	HintLabel.Size = UDim2.new(1, 0, 0, 20)
	HintLabel.BackgroundTransparency = 1
	HintLabel.Text = "Select all (Ctrl+A) and copy (Ctrl+C)"
	HintLabel.TextColor3 = Theme.Colors.TextMuted
	HintLabel.FontFace = Theme.Fonts.Default
	HintLabel.TextSize = Theme.TextSizes.Small
	HintLabel.TextXAlignment = Enum.TextXAlignment.Center
	HintLabel.LayoutOrder = 2
	HintLabel.ZIndex = Theme.ZIndex.Modal + 2
	HintLabel.Parent = Dialog

	local TextBoxContainer = Instance.new("Frame")
	TextBoxContainer.Name = "TextBoxContainer"
	TextBoxContainer.Size = UDim2.new(1, 0, 1, -100)
	TextBoxContainer.BackgroundColor3 = Theme.Colors.BackgroundDark
	TextBoxContainer.BorderSizePixel = 0
	TextBoxContainer.LayoutOrder = 3
	TextBoxContainer.ZIndex = Theme.ZIndex.Modal + 2
	TextBoxContainer.Parent = Dialog

	Theme.ApplyCorner(TextBoxContainer, Theme.Sizes.BorderRadiusSmall)

	local TextBoxScroll = Instance.new("ScrollingFrame")
	TextBoxScroll.Name = "Scroll"
	TextBoxScroll.Size = UDim2.new(1, -8, 1, -8)
	TextBoxScroll.Position = UDim2.fromOffset(4, 4)
	TextBoxScroll.BackgroundTransparency = 1
	TextBoxScroll.ScrollBarThickness = 6
	TextBoxScroll.ScrollBarImageColor3 = Theme.Colors.BorderLight
	TextBoxScroll.CanvasSize = UDim2.fromScale(0, 0)
	TextBoxScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TextBoxScroll.ZIndex = Theme.ZIndex.Modal + 2
	TextBoxScroll.Parent = TextBoxContainer

	local JsonTextBox = Instance.new("TextBox")
	JsonTextBox.Name = "JsonTextBox"
	JsonTextBox.Size = UDim2.fromScale(1, 0)
	JsonTextBox.AutomaticSize = Enum.AutomaticSize.Y
	JsonTextBox.BackgroundTransparency = 1
	JsonTextBox.Text = Config.JsonContent
	JsonTextBox.TextColor3 = Theme.Colors.Text
	JsonTextBox.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	JsonTextBox.TextSize = 12
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