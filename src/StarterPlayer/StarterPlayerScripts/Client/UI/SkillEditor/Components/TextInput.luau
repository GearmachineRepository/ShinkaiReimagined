--!strict

local Theme = require(script.Parent.Parent.Theme)

local TextInput = {}

export type TextInputConfig = {
	Name: string?,
	Text: string?,
	PlaceholderText: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor: Color3?,
	TextColor: Color3?,
	PlaceholderColor: Color3?,
	Font: Font?,
	TextSize: number?,
	ClearTextOnFocus: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: GuiObject?,
	OnChanged: ((Text: string) -> ())?,
	OnFocusLost: ((Text: string, EnterPressed: boolean) -> ())?,
}

export type TextInputInstance = {
	Frame: Frame,
	TextBox: TextBox,
	GetText: () -> string,
	SetText: (Text: string) -> (),
	SetPlaceholder: (Text: string) -> (),
	Focus: () -> (),
	Destroy: () -> (),
}

function TextInput.Create(Config: TextInputConfig): TextInputInstance
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "TextInput"
	Container.Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Container.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.BackgroundDark
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Config.LayoutOrder or 0
	Container.ZIndex = BaseZIndex

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusSmall)
	local Stroke = Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Input = Instance.new("TextBox")
	Input.Name = "Input"
	Input.Size = UDim2.new(1, -12, 1, 0)
	Input.Position = UDim2.fromOffset(6, 0)
	Input.BackgroundTransparency = 1
	Input.Text = Config.Text or ""
	Input.PlaceholderText = Config.PlaceholderText or ""
	Input.TextColor3 = Config.TextColor or Theme.Colors.Text
	Input.PlaceholderColor3 = Config.PlaceholderColor or Theme.Colors.TextMuted
	Input.FontFace = Config.Font or Theme.Fonts.Default
	Input.TextSize = Config.TextSize or Theme.TextSizes.Default
	Input.TextXAlignment = Enum.TextXAlignment.Left
	Input.ClearTextOnFocus = Config.ClearTextOnFocus or false
	Input.ZIndex = BaseZIndex + 1
	Input.Parent = Container

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, Input.Focused:Connect(function()
		Stroke.Color = Theme.Colors.BorderFocus
	end))

	table.insert(Connections, Input.FocusLost:Connect(function(EnterPressed: boolean)
		Stroke.Color = Theme.Colors.Border
		if Config.OnFocusLost then
			Config.OnFocusLost(Input.Text, EnterPressed)
		end
	end))

	table.insert(Connections, Input:GetPropertyChangedSignal("Text"):Connect(function()
		if Config.OnChanged then
			Config.OnChanged(Input.Text)
		end
	end))

	local Instance = {
		Frame = Container,
		TextBox = Input,
	}

	function Instance.GetText(): string
		return Input.Text
	end

	function Instance.SetText(Text: string)
		Input.Text = Text
	end

	function Instance.SetPlaceholder(Text: string)
		Input.PlaceholderText = Text
	end

	function Instance.Focus()
		Input:CaptureFocus()
	end

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return Instance
end

return TextInput