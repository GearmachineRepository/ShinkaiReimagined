--!strict

local Theme = require(script.Parent.Parent.Theme)

local Button = {}

export type ButtonConfig = {
	Name: string?,
	Text: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	HoverColor: Color3?,
	ActiveColor: Color3?,
	TextColor: Color3?,
	Font: Font?,
	TextSize: number?,
	CornerRadius: UDim?,
	LayoutOrder: number?,
	ZIndex: number?,
	Enabled: boolean?,
	Parent: GuiObject?,
	OnClick: (() -> ())?,
}

export type ButtonInstance = {
	Frame: TextButton,
	SetText: (Text: string) -> (),
	SetEnabled: (Enabled: boolean) -> (),
	SetOnClick: (Callback: () -> ()) -> (),
	Destroy: () -> (),
}

function Button.Create(Config: ButtonConfig): ButtonInstance
	local BackgroundColor = Config.BackgroundColor or Theme.Colors.Surface
	local HoverColor = Config.HoverColor or Theme.Colors.SurfaceHover
	local ActiveColor = Config.ActiveColor or Theme.Colors.SurfaceActive
	local TextColor = Config.TextColor or Theme.Colors.Text
	local Enabled = if Config.Enabled ~= nil then Config.Enabled else true
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local OnClickCallback = Config.OnClick

	local ButtonFrame = Instance.new("TextButton")
	ButtonFrame.Name = Config.Name or "Button"
	ButtonFrame.Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.ButtonHeight)
	ButtonFrame.Position = Config.Position or UDim2.fromScale(0, 0)
	ButtonFrame.AnchorPoint = Config.AnchorPoint or Vector2.zero
	ButtonFrame.BackgroundColor3 = BackgroundColor
	ButtonFrame.BorderSizePixel = 0
	ButtonFrame.LayoutOrder = Config.LayoutOrder or 0
	ButtonFrame.AutoButtonColor = false
	ButtonFrame.ZIndex = BaseZIndex

	ButtonFrame.Text = Config.Text or ""
	ButtonFrame.TextColor3 = TextColor
	ButtonFrame.FontFace = Config.Font or Theme.Fonts.Default
	ButtonFrame.TextSize = Config.TextSize or Theme.TextSizes.Default

	Theme.ApplyCorner(ButtonFrame, Config.CornerRadius)
	Theme.ApplyStroke(ButtonFrame, Theme.Colors.Border)

	if Config.Parent then
		ButtonFrame.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}

	local function UpdateVisual(Hovered: boolean, Pressed: boolean)
		if not Enabled then
			ButtonFrame.BackgroundColor3 = Theme.Colors.BackgroundDark
			ButtonFrame.TextColor3 = Theme.Colors.TextDisabled
			return
		end

		if Pressed then
			ButtonFrame.BackgroundColor3 = ActiveColor
		elseif Hovered then
			ButtonFrame.BackgroundColor3 = HoverColor
		else
			ButtonFrame.BackgroundColor3 = BackgroundColor
		end
		ButtonFrame.TextColor3 = TextColor
	end

	local IsHovered = false
	local IsPressed = false

	table.insert(Connections, ButtonFrame.MouseEnter:Connect(function()
		IsHovered = true
		UpdateVisual(IsHovered, IsPressed)
	end))

	table.insert(Connections, ButtonFrame.MouseLeave:Connect(function()
		IsHovered = false
		IsPressed = false
		UpdateVisual(IsHovered, IsPressed)
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Down:Connect(function()
		if not Enabled then
			return
		end
		IsPressed = true
		UpdateVisual(IsHovered, IsPressed)
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Up:Connect(function()
		IsPressed = false
		UpdateVisual(IsHovered, IsPressed)
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Click:Connect(function()
		if not Enabled then
			return
		end
		if OnClickCallback then
			OnClickCallback()
		end
	end))

	local Instance = {
		Frame = ButtonFrame,
	}

	function Instance.SetText(Text: string)
		ButtonFrame.Text = Text
	end

	function Instance.SetEnabled(NewEnabled: boolean)
		Enabled = NewEnabled
		UpdateVisual(IsHovered, IsPressed)
	end

	function Instance.SetOnClick(Callback: () -> ())
		OnClickCallback = Callback
	end

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		ButtonFrame:Destroy()
	end

	return Instance
end

export type IconButtonConfig = ButtonConfig & {
	Icon: string?,
	IconSize: UDim2?,
}

function Button.CreateIcon(Config: IconButtonConfig): ButtonInstance
	local BaseButton = Button.Create(Config)
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	if Config.Icon then
		local IconImage = Instance.new("ImageLabel")
		IconImage.Name = "Icon"
		IconImage.Size = Config.IconSize or UDim2.fromOffset(16, 16)
		IconImage.Position = UDim2.fromScale(0.5, 0.5)
		IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
		IconImage.BackgroundTransparency = 1
		IconImage.Image = Config.Icon
		IconImage.ImageColor3 = Config.TextColor or Theme.Colors.Text
		IconImage.ZIndex = BaseZIndex + 1
		IconImage.Parent = BaseButton.Frame
	end

	return BaseButton
end

return Button