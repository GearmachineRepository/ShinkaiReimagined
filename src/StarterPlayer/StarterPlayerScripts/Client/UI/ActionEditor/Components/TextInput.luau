--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

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

	local Container = UILibrary.SurfaceContainer({
		Name = Config.Name or "TextInput",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	Container.BackgroundColor3 = Config.BackgroundColor or Theme.Colors.BackgroundDark

	local Stroke = Container:FindFirstChildOfClass("UIStroke")

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

	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, Input.Focused:Connect(function()
		if Stroke then
			Stroke.Color = Theme.Colors.BorderFocus
		end
	end))

	table.insert(Connections, Input.FocusLost:Connect(function(EnterPressed: boolean)
		if Stroke then
			Stroke.Color = Theme.Colors.Border
		end
		if Config.OnFocusLost then
			Config.OnFocusLost(Input.Text, EnterPressed)
		end
	end))

	table.insert(Connections, Input:GetPropertyChangedSignal("Text"):Connect(function()
		if Config.OnChanged then
			Config.OnChanged(Input.Text)
		end
	end))

	local InputInstance: TextInputInstance = {
		Frame = Container,
		TextBox = Input,
	} :: any

	function InputInstance.GetText(): string
		return Input.Text
	end

	function InputInstance.SetText(Text: string)
		Input.Text = Text
	end

	function InputInstance.SetPlaceholder(Text: string)
		Input.PlaceholderText = Text
	end

	function InputInstance.Focus()
		Input:CaptureFocus()
	end

	function InputInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return InputInstance
end

return TextInput