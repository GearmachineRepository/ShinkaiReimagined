--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)

local Comment = {}

local MIN_WIDTH = 150
local MIN_HEIGHT = 80
local RESIZE_HANDLE_SIZE = 20
local DEFAULT_WIDTH = 300
local DEFAULT_HEIGHT = 150
local DEFAULT_COLOR = Color3.fromRGB(50, 50, 55)

export type CommentConfig = {
	CommentId: string,
	Title: string?,
	Text: string?,
	Color: Color3?,
	Position: Vector2?,
	Size: Vector2?,
	Parent: GuiObject?,
	OnSelected: ((CommentId: string) -> ())?,
	OnMoved: ((CommentId: string, Position: Vector2) -> ())?,
	OnResized: ((CommentId: string, Size: Vector2) -> ())?,
	OnTitleChanged: ((CommentId: string, Title: string) -> ())?,
	OnTextChanged: ((CommentId: string, Text: string) -> ())?,
}

export type CommentInstance = {
	Frame: Frame,
	CommentId: string,
	GetPosition: () -> Vector2,
	SetPosition: (Position: Vector2) -> (),
	GetSize: () -> Vector2,
	SetSize: (Size: Vector2) -> (),
	GetTitle: () -> string,
	SetTitle: (Title: string) -> (),
	GetText: () -> string,
	SetText: (Text: string) -> (),
	GetColor: () -> Color3,
	SetColor: (Color: Color3) -> (),
	SetSelected: (Selected: boolean) -> (),
	Destroy: () -> (),
}

Comment.DefaultColor = DEFAULT_COLOR

function Comment.Create(Config: CommentConfig): CommentInstance
	local Position = Config.Position or Vector2.zero
	local Size = Config.Size or Vector2.new(DEFAULT_WIDTH, DEFAULT_HEIGHT)
	local Color = Config.Color or DEFAULT_COLOR
	local Title = Config.Title or "Comment"
	local Text = Config.Text or ""
	local IsSelected = false

	local Container = Instance.new("Frame")
	Container.Name = "Comment_" .. Config.CommentId
	Container.Size = UDim2.fromOffset(Size.X, Size.Y)
	Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	Container.BackgroundColor3 = Color
	Container.BackgroundTransparency = 0.2
	Container.BorderSizePixel = 0
	Container.ZIndex = Theme.ZIndex.BranchContainer
	Container.Active = true

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusLarge)
	local Stroke = Theme.ApplyStroke(Container, Color3.fromRGB(85, 85, 90))
	Stroke.Transparency = 0.2

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 28)
	Header.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	Header.BackgroundTransparency = 0
	Header.BorderSizePixel = 0
	Header.ZIndex = Theme.ZIndex.BranchContainer + 1
	Header.Active = false
	Header.Parent = Container

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = Theme.Sizes.BorderRadiusLarge
	HeaderCorner.Parent = Header

	local HeaderMask = Instance.new("Frame")
	HeaderMask.Name = "HeaderMask"
	HeaderMask.Size = UDim2.new(1, 0, 0, 12)
	HeaderMask.Position = UDim2.new(0, 0, 1, -12)
	HeaderMask.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	HeaderMask.BackgroundTransparency = 0
	HeaderMask.BorderSizePixel = 0
	HeaderMask.ZIndex = Theme.ZIndex.BranchContainer + 1
	HeaderMask.Active = false
	HeaderMask.Parent = Header

	local TitleInput = Instance.new("TextBox")
	TitleInput.Name = "TitleInput"
	TitleInput.Size = UDim2.new(1, -16, 1, 0)
	TitleInput.Position = UDim2.fromOffset(8, 0)
	TitleInput.BackgroundTransparency = 1
	TitleInput.Text = Title
	TitleInput.TextColor3 = Color3.fromRGB(230, 230, 230)
	TitleInput.FontFace = Theme.Fonts.Bold
	TitleInput.TextSize = Theme.TextSizes.Default
	TitleInput.TextXAlignment = Enum.TextXAlignment.Left
	TitleInput.ClearTextOnFocus = false
	TitleInput.ZIndex = Theme.ZIndex.BranchContainer + 2
	TitleInput.Parent = Header

	local ContentArea = Instance.new("ScrollingFrame")
	ContentArea.Name = "Content"
	ContentArea.Size = UDim2.new(1, -16, 1, -48)
	ContentArea.Position = UDim2.fromOffset(8, 34)
	ContentArea.BackgroundTransparency = 1
	ContentArea.BorderSizePixel = 0
	ContentArea.ScrollBarThickness = 4
	ContentArea.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 85)
	ContentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
	ContentArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ContentArea.ZIndex = Theme.ZIndex.BranchContainer + 1
	ContentArea.Active = false
	ContentArea.Parent = Container

	local TextInput = Instance.new("TextBox")
	TextInput.Name = "TextInput"
	TextInput.Size = UDim2.fromScale(1, 0)
	TextInput.AutomaticSize = Enum.AutomaticSize.Y
	TextInput.BackgroundTransparency = 1
	TextInput.Text = Text
	TextInput.TextColor3 = Color3.fromRGB(170, 170, 175)
	TextInput.FontFace = Theme.Fonts.Default
	TextInput.TextSize = Theme.TextSizes.Small
	TextInput.TextXAlignment = Enum.TextXAlignment.Left
	TextInput.TextYAlignment = Enum.TextYAlignment.Top
	TextInput.TextWrapped = true
	TextInput.MultiLine = true
	TextInput.ClearTextOnFocus = false
	TextInput.ZIndex = Theme.ZIndex.BranchContainer + 2
	TextInput.Parent = ContentArea

	local ResizeHandle = Instance.new("Frame")
	ResizeHandle.Name = "ResizeHandle"
	ResizeHandle.Size = UDim2.fromOffset(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE)
	ResizeHandle.Position = UDim2.new(1, -RESIZE_HANDLE_SIZE, 1, -RESIZE_HANDLE_SIZE)
	ResizeHandle.BackgroundColor3 = Color3.fromRGB(100, 100, 105)
	ResizeHandle.BackgroundTransparency = 0.5
	ResizeHandle.BorderSizePixel = 0
	ResizeHandle.ZIndex = Theme.ZIndex.BranchContainer + 3
	ResizeHandle.Active = true
	ResizeHandle.Parent = Container

	Theme.ApplyCorner(ResizeHandle, UDim.new(0, 4))

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}
	local IsDragging = false
	local IsResizing = false
	local DragStartPosition = Vector2.zero
	local DragStartMouse = Vector2.zero
	local ResizeStartSize = Vector2.zero
	local ResizeStartMouse = Vector2.zero

	local function GetZoomScale(): number
		local Parent = Container.Parent
		if Parent then
			local UIScaleObj = Parent:FindFirstChild("ZoomScale")
			if UIScaleObj and UIScaleObj:IsA("UIScale") then
				return UIScaleObj.Scale
			end
		end
		return 1
	end

	local function UpdateSelection()
		if IsSelected then
			Stroke.Color = Theme.Colors.BorderFocus
			Stroke.Transparency = 0
			Stroke.Thickness = 2
		else
			Stroke.Color = Color3.fromRGB(85, 85, 90)
			Stroke.Transparency = 0.2
			Stroke.Thickness = 1
		end
	end

	local function IsPointInResizeHandle(ScreenPoint: Vector2): boolean
		local HandlePos = ResizeHandle.AbsolutePosition
		local HandleSize = ResizeHandle.AbsoluteSize
		return ScreenPoint.X >= HandlePos.X
			and ScreenPoint.X <= HandlePos.X + HandleSize.X
			and ScreenPoint.Y >= HandlePos.Y
			and ScreenPoint.Y <= HandlePos.Y + HandleSize.Y
	end

	local function IsClickOnSelf(ScreenPoint: Vector2): boolean
		local PlayerGui = Container:FindFirstAncestorOfClass("PlayerGui")
		if not PlayerGui then
			return true
		end

		local GuisAtPosition = PlayerGui:GetGuiObjectsAtPosition(ScreenPoint.X, ScreenPoint.Y)
		for _, Gui in GuisAtPosition do
			if Gui == Container or Gui:IsDescendantOf(Container) then
				return true
			end
			if Gui.Active and Gui:IsA("GuiObject") then
				return false
			end
		end
		return true
	end

	table.insert(Connections, Container.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			local ClickPos = Vector2.new(Input.Position.X, Input.Position.Y)
			if IsPointInResizeHandle(ClickPos) then
				return
			end
			if not IsClickOnSelf(ClickPos) then
				return
			end

			IsDragging = true
			DragStartPosition = Position
			DragStartMouse = ClickPos

			if Config.OnSelected then
				Config.OnSelected(Config.CommentId)
			end
		end
	end))

	table.insert(Connections, ResizeHandle.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsResizing = true
			ResizeStartSize = Size
			ResizeStartMouse = Vector2.new(Input.Position.X, Input.Position.Y)
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local Zoom = GetZoomScale()
		local CurrentMouse = Vector2.new(Input.Position.X, Input.Position.Y)

		if IsDragging then
			local ScreenDelta = CurrentMouse - DragStartMouse
			local WorldDelta = ScreenDelta / Zoom
			Position = DragStartPosition + WorldDelta
			Container.Position = UDim2.fromOffset(Position.X, Position.Y)

			if Config.OnMoved then
				Config.OnMoved(Config.CommentId, Position)
			end
		end

		if IsResizing then
			local ScreenDelta = CurrentMouse - ResizeStartMouse
			local WorldDelta = ScreenDelta / Zoom
			local NewWidth = math.max(MIN_WIDTH, ResizeStartSize.X + WorldDelta.X)
			local NewHeight = math.max(MIN_HEIGHT, ResizeStartSize.Y + WorldDelta.Y)
			Size = Vector2.new(NewWidth, NewHeight)
			Container.Size = UDim2.fromOffset(Size.X, Size.Y)

			if Config.OnResized then
				Config.OnResized(Config.CommentId, Size)
			end
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = false
			IsResizing = false
		end
	end))

	table.insert(Connections, TitleInput.FocusLost:Connect(function()
		Title = TitleInput.Text
		if Config.OnTitleChanged then
			Config.OnTitleChanged(Config.CommentId, Title)
		end
	end))

	table.insert(Connections, TextInput.FocusLost:Connect(function()
		Text = TextInput.Text
		if Config.OnTextChanged then
			Config.OnTextChanged(Config.CommentId, Text)
		end
	end))

	table.insert(Connections, ResizeHandle.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			ResizeHandle.BackgroundTransparency = 0.2
		end
	end))

	table.insert(Connections, ResizeHandle.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			ResizeHandle.BackgroundTransparency = 0.5
		end
	end))

	local CommentObj: CommentInstance = {
		Frame = Container,
		CommentId = Config.CommentId,
	} :: any

	function CommentObj.GetPosition(): Vector2
		return Position
	end

	function CommentObj.SetPosition(NewPosition: Vector2)
		Position = NewPosition
		Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	end

	function CommentObj.GetSize(): Vector2
		return Size
	end

	function CommentObj.SetSize(NewSize: Vector2)
		Size = Vector2.new(
			math.max(MIN_WIDTH, NewSize.X),
			math.max(MIN_HEIGHT, NewSize.Y)
		)
		Container.Size = UDim2.fromOffset(Size.X, Size.Y)
	end

	function CommentObj.GetTitle(): string
		return Title
	end

	function CommentObj.SetTitle(NewTitle: string)
		Title = NewTitle
		TitleInput.Text = NewTitle
	end

	function CommentObj.GetText(): string
		return Text
	end

	function CommentObj.SetText(NewText: string)
		Text = NewText
		TextInput.Text = NewText
	end

	function CommentObj.GetColor(): Color3
		return Color
	end

	function CommentObj.SetColor(NewColor: Color3)
		Color = NewColor
		Container.BackgroundColor3 = NewColor
	end

	function CommentObj.SetSelected(Selected: boolean)
		IsSelected = Selected
		UpdateSelection()
	end

	function CommentObj.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return CommentObj
end

return Comment