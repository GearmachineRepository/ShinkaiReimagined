--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

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

	local ButtonFrame = UILibrary.SecondaryButton({
		Name = Config.Name or "Button",
		Text = Config.Text or "Button",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.ButtonHeight),
		Position = Config.Position,
		AnchorPoint = Config.AnchorPoint,
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	ButtonFrame.BackgroundColor3 = BackgroundColor
	ButtonFrame.TextColor3 = TextColor

	if Config.Font then
		ButtonFrame.FontFace = Config.Font
	end

	if Config.TextSize then
		ButtonFrame.TextSize = Config.TextSize
	end

	local Connections: { RBXScriptConnection } = {}

	table.insert(Connections, ButtonFrame.MouseEnter:Connect(function()
		if Enabled then
			ButtonFrame.BackgroundColor3 = HoverColor
		end
	end))

	table.insert(Connections, ButtonFrame.MouseLeave:Connect(function()
		if Enabled then
			ButtonFrame.BackgroundColor3 = BackgroundColor
		end
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Down:Connect(function()
		if Enabled then
			ButtonFrame.BackgroundColor3 = ActiveColor
		end
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Up:Connect(function()
		if Enabled then
			ButtonFrame.BackgroundColor3 = HoverColor
		end
	end))

	table.insert(Connections, ButtonFrame.MouseButton1Click:Connect(function()
		if Enabled and OnClickCallback then
			OnClickCallback()
		end
	end))

	local ButtonInstance: ButtonInstance = {
		Frame = ButtonFrame,
	} :: any

	function ButtonInstance.SetText(Text: string)
		ButtonFrame.Text = Text
	end

	function ButtonInstance.SetEnabled(NewEnabled: boolean)
		Enabled = NewEnabled
		if Enabled then
			ButtonFrame.BackgroundColor3 = BackgroundColor
			ButtonFrame.TextColor3 = TextColor
		else
			ButtonFrame.BackgroundColor3 = Theme.Colors.SurfaceActive
			ButtonFrame.TextColor3 = Theme.Colors.TextMuted
		end
	end

	function ButtonInstance.SetOnClick(Callback: () -> ())
		OnClickCallback = Callback
	end

	function ButtonInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		ButtonFrame:Destroy()
	end

	return ButtonInstance
end

return Button