--!strict

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local DropdownState = require(script.Parent.Parent.State.DropdownState)

local Canvas = {}

export type CanvasConfig = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	GridImage: string?,
	Parent: GuiObject?,
	OnOffsetChanged: ((Offset: Vector2) -> ())?,
	OnZoomChanged: ((Zoom: number) -> ())?,
	OnBackgroundClick: (() -> ())?,
}

export type CanvasInstance = {
	Frame: Frame,
	Content: Frame,
	GetOffset: () -> Vector2,
	SetOffset: (Offset: Vector2) -> (),
	GetZoom: () -> number,
	SetZoom: (Zoom: number) -> (),
	WorldToCanvas: (WorldPosition: Vector2) -> Vector2,
	CanvasToWorld: (CanvasPosition: Vector2) -> Vector2,
	Destroy: () -> (),
}

local MIN_ZOOM = 0.25
local MAX_ZOOM = 2
local ZOOM_STEP = 0.1
local GRID_SIZE = 100
local GRID_WORLD_SIZE = 20000

function Canvas.Create(Config: CanvasConfig): CanvasInstance
	local Offset = Vector2.zero
	local Zoom = 1
	local IsMouseOver = false

	local Container = Instance.new("Frame")
	Container.Name = Config.Name or "Canvas"
	Container.Size = Config.Size or UDim2.fromScale(1, 1)
	Container.Position = Config.Position or UDim2.fromScale(0, 0)
	Container.AnchorPoint = Config.AnchorPoint or Vector2.zero
	Container.BackgroundColor3 = Theme.Colors.BackgroundDark
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = true

	local ClickDetector = Instance.new("TextButton")
	ClickDetector.Name = "ClickDetector"
	ClickDetector.Size = UDim2.fromScale(1, 1)
	ClickDetector.BackgroundTransparency = 1
	ClickDetector.Text = ""
	ClickDetector.ZIndex = 2
	ClickDetector.Parent = Container

	local Content = Instance.new("Frame")
	Content.Name = "Content"
	Content.Size = UDim2.fromScale(1, 1)
	Content.Position = UDim2.fromScale(0.5, 0.5)
	Content.AnchorPoint = Vector2.new(0.5, 0.5)
	Content.BackgroundTransparency = 1
	Content.ZIndex = 3
	Content.Parent = Container

	local UIScaleObj = Instance.new("UIScale")
	UIScaleObj.Name = "ZoomScale"
	UIScaleObj.Scale = 1
	UIScaleObj.Parent = Content

	local GridBackground = Instance.new("ImageLabel")
	GridBackground.Name = "Grid"
	GridBackground.Size = UDim2.fromOffset(GRID_WORLD_SIZE, GRID_WORLD_SIZE)
	GridBackground.Position = UDim2.fromOffset(-GRID_WORLD_SIZE / 2, -GRID_WORLD_SIZE / 2)
	GridBackground.BackgroundTransparency = 1
	GridBackground.Image = if Config.GridImage then Config.GridImage else ""
	GridBackground.ImageColor3 = Color3.fromRGB(255, 255, 255)
	GridBackground.ImageTransparency = 0.925
	GridBackground.ScaleType = Enum.ScaleType.Tile
	GridBackground.TileSize = UDim2.fromOffset(GRID_SIZE, GRID_SIZE)
	GridBackground.ZIndex = 1
	GridBackground.Parent = Content

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}
	local IsPanning = false
	local PanStartOffset = Vector2.zero
	local PanStartMouse = Vector2.zero
	local ClickStartedOnBackground = false

	local function UpdateContentTransform()
		Content.Position = UDim2.new(0.5, Offset.X, 0.5, Offset.Y)
		UIScaleObj.Scale = Zoom
	end

	table.insert(Connections, Container.MouseEnter:Connect(function()
		IsMouseOver = true
	end))

	table.insert(Connections, Container.MouseLeave:Connect(function()
		IsMouseOver = false
	end))

	table.insert(Connections, ClickDetector.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			ClickStartedOnBackground = true
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ClickStartedOnBackground then
				local MousePos = UserInputService:GetMouseLocation()
				local GuiInset = GuiService:GetGuiInset()
				MousePos = MousePos - GuiInset

				local PlayerGui = Container:FindFirstAncestorOfClass("PlayerGui")
				if PlayerGui then
					local GuisAtPosition = PlayerGui:GetGuiObjectsAtPosition(MousePos.X, MousePos.Y)
					local HitBackground = false
					for _, Gui in GuisAtPosition do
						if Gui == ClickDetector then
							HitBackground = true
							break
						end
						local GuiObject = Gui :: GuiObject
						if GuiObject.Active and Gui:IsDescendantOf(Content) then
							break
						end
					end
					if HitBackground and Config.OnBackgroundClick then
						Config.OnBackgroundClick()
					end
				end
			end
			ClickStartedOnBackground = false
		end
	end))

	table.insert(Connections, Container.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton3 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
			if DropdownState.IsAnyOpen() then
				return
			end
			IsPanning = true
			PanStartOffset = Offset
			PanStartMouse = Vector2.new(Input.Position.X, Input.Position.Y)
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if IsPanning and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local CurrentMouse = Vector2.new(Input.Position.X, Input.Position.Y)
			local Delta = CurrentMouse - PanStartMouse
			Offset = PanStartOffset + Delta
			UpdateContentTransform()

			if Config.OnOffsetChanged then
				Config.OnOffsetChanged(Offset)
			end
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton3 or Input.UserInputType == Enum.UserInputType.MouseButton2 then
			IsPanning = false
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseWheel then
			if not IsMouseOver then
				return
			end

			if DropdownState.IsAnyOpen() then
				return
			end

			local MousePosition = UserInputService:GetMouseLocation()
			local GuiInset = GuiService:GetGuiInset()
			MousePosition = MousePosition - GuiInset

			local ContainerPosition = Container.AbsolutePosition
			local ContainerSize = Container.AbsoluteSize

			local IsInsideCanvas = MousePosition.X >= ContainerPosition.X
				and MousePosition.X <= ContainerPosition.X + ContainerSize.X
				and MousePosition.Y >= ContainerPosition.Y
				and MousePosition.Y <= ContainerPosition.Y + ContainerSize.Y

			if not IsInsideCanvas then
				return
			end

			local RelativeMousePosition = MousePosition - ContainerPosition - (ContainerSize / 2)

			local OldZoom = Zoom
			local ZoomDelta = Input.Position.Z * ZOOM_STEP
			Zoom = math.clamp(Zoom + ZoomDelta, MIN_ZOOM, MAX_ZOOM)

			local ZoomRatio = Zoom / OldZoom
			Offset = Offset * ZoomRatio + RelativeMousePosition * (1 - ZoomRatio)

			UpdateContentTransform()

			if Config.OnZoomChanged then
				Config.OnZoomChanged(Zoom)
			end
			if Config.OnOffsetChanged then
				Config.OnOffsetChanged(Offset)
			end
		end
	end))

	UpdateContentTransform()

	local CanvasObj = {
		Frame = Container,
		Content = Content,
	}

	function CanvasObj.GetOffset(): Vector2
		return Offset
	end

	function CanvasObj.SetOffset(NewOffset: Vector2)
		Offset = NewOffset
		UpdateContentTransform()
	end

	function CanvasObj.GetZoom(): number
		return Zoom
	end

	function CanvasObj.SetZoom(NewZoom: number)
		Zoom = math.clamp(NewZoom, MIN_ZOOM, MAX_ZOOM)
		UpdateContentTransform()
	end

	function CanvasObj.WorldToCanvas(WorldPosition: Vector2): Vector2
		return (WorldPosition * Zoom) + Offset
	end

	function CanvasObj.CanvasToWorld(CanvasPosition: Vector2): Vector2
		return (CanvasPosition - Offset) / Zoom
	end

	function CanvasObj.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
		Container:Destroy()
	end

	return CanvasObj
end

return Canvas