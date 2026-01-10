--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local Wire = {}

local BEZIER_SEGMENTS = 20
local WIRE_CURVATURE = 80

export type WireConfig = {
	WireId: string,
	WireType: Types.PortType,
	Parent: GuiObject?,
	OnClick: ((WireId: string) -> ())?,
	CanInteract: (() -> boolean)?,
}

export type WireInstance = {
	Frame: Frame,
	WireId: string,
	WireType: Types.PortType,
	SetPositions: (StartPosition: Vector2, EndPosition: Vector2) -> (),
	SetHighlighted: (Highlighted: boolean) -> (),
	SetSelected: (Selected: boolean) -> (),
	Destroy: () -> (),
}

local function CubicBezier(P0: Vector2, P1: Vector2, P2: Vector2, P3: Vector2, T: number): Vector2
	local OneMinusT = 1 - T
	local OneMinusT2 = OneMinusT * OneMinusT
	local OneMinusT3 = OneMinusT2 * OneMinusT
	local T2 = T * T
	local T3 = T2 * T

	return (P0 * OneMinusT3) + (P1 * 3 * OneMinusT2 * T) + (P2 * 3 * OneMinusT * T2) + (P3 * T3)
end

function Wire.Create(Config: WireConfig): WireInstance
	local WireColor = if Config.WireType == "Flow" then Theme.Colors.WireFlow else Theme.Colors.WireSignal
	local StartPosition = Vector2.zero
	local EndPosition = Vector2.new(100, 0)
	local IsHighlighted = false

	local Container = Instance.new("Frame")
	Container.Name = "Wire_" .. Config.WireId
	Container.Size = UDim2.fromScale(1, 1)
	Container.Position = UDim2.fromScale(0, 0)
	Container.BackgroundTransparency = 1
	Container.ZIndex = Theme.ZIndex.Wire
	Container.Parent = Config.Parent

	local Segments: { Frame } = {}
	local ClickDetectors: { TextButton } = {}

	for Index = 1, BEZIER_SEGMENTS do
		local Segment = Instance.new("Frame")
		Segment.Name = "Segment_" .. Index
		Segment.BackgroundColor3 = WireColor
		Segment.BorderSizePixel = 0
		Segment.AnchorPoint = Vector2.new(0, 0.5)
		Segment.ZIndex = Theme.ZIndex.Wire
		Segment.Parent = Container

		Theme.ApplyCorner(Segment, UDim.new(0.5, 0))

		local ClickDetector = Instance.new("TextButton")
		ClickDetector.Name = "Click_" .. Index
		ClickDetector.Size = UDim2.new(1, 0, 0, 12)
		ClickDetector.Position = UDim2.fromScale(0, 0.5)
		ClickDetector.AnchorPoint = Vector2.new(0, 0.5)
		ClickDetector.BackgroundTransparency = 1
		ClickDetector.Text = ""
		ClickDetector.ZIndex = Theme.ZIndex.Wire + 1
		ClickDetector.Parent = Segment

		ClickDetector.MouseEnter:Connect(function()
			local CanInteract = Config.CanInteract
			if CanInteract and not CanInteract() then
				return
			end
			if not IsHighlighted then
				for _, Seg in Segments do
					Seg.BackgroundColor3 = Theme.Colors.BorderFocus
				end
			end
		end)

		ClickDetector.MouseLeave:Connect(function()
			if not IsHighlighted then
				for _, Seg in Segments do
					Seg.BackgroundColor3 = WireColor
				end
			end
		end)

		ClickDetector.MouseButton1Click:Connect(function()
			local CanInteract = Config.CanInteract
			if CanInteract and not CanInteract() then
				return
			end
			if Config.OnClick then
				Config.OnClick(Config.WireId)
			end
		end)

		table.insert(Segments, Segment)
		table.insert(ClickDetectors, ClickDetector)
	end

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

	local function UpdateWire()
		local Zoom = GetZoomScale()

		local Parent = Container.Parent :: GuiObject?
		if not Parent then
			return
		end

		local ParentAbsPos = Parent.AbsolutePosition

		local AdjustedStart = (StartPosition - ParentAbsPos) / Zoom
		local AdjustedEnd = (EndPosition - ParentAbsPos) / Zoom

		local ControlOffset = math.abs(AdjustedEnd.X - AdjustedStart.X) * 0.5
		ControlOffset = math.max(ControlOffset, WIRE_CURVATURE)

		local P0 = AdjustedStart
		local P1 = AdjustedStart + Vector2.new(ControlOffset, 0)
		local P2 = AdjustedEnd - Vector2.new(ControlOffset, 0)
		local P3 = AdjustedEnd

		for Index, Segment in Segments do
			local T0 = (Index - 1) / BEZIER_SEGMENTS
			local T1 = Index / BEZIER_SEGMENTS

			local Point0 = CubicBezier(P0, P1, P2, P3, T0)
			local Point1 = CubicBezier(P0, P1, P2, P3, T1)

			local Delta = Point1 - Point0
			local Length = Delta.Magnitude
			local Angle = math.atan2(Delta.Y, Delta.X)

			Segment.Size = UDim2.fromOffset(math.max(Length + 2, 4), Theme.Sizes.WireThickness)
			Segment.Position = UDim2.fromOffset(Point0.X, Point0.Y)
			Segment.Rotation = math.deg(Angle)
		end
	end

	UpdateWire()

	local Instance: WireInstance = {
		Frame = Container,
		WireId = Config.WireId,
		WireType = Config.WireType,
	} :: any

	function Instance.SetPositions(NewStartPosition: Vector2, NewEndPosition: Vector2)
		StartPosition = NewStartPosition
		EndPosition = NewEndPosition
		UpdateWire()
	end

	function Instance.SetHighlighted(Highlighted: boolean)
		IsHighlighted = Highlighted
		local NewThickness = if Highlighted then Theme.Sizes.WireThicknessHover else Theme.Sizes.WireThickness
		local NewColor = if Highlighted then Theme.Colors.BorderFocus else WireColor

		for _, Segment in Segments do
			Segment.Size = UDim2.fromOffset(Segment.Size.X.Offset, NewThickness)
			Segment.BackgroundColor3 = NewColor
		end
	end

	function Instance.SetSelected(Selected: boolean)
		local NewColor = if Selected then Theme.Colors.Primary else WireColor

		for _, Segment in Segments do
			Segment.BackgroundColor3 = NewColor
		end
	end

	function Instance.Destroy()
		for _, Segment in Segments do
			Segment:Destroy()
		end
		table.clear(Segments)
		table.clear(ClickDetectors)
		Container:Destroy()
	end

	return Instance
end

function Wire.CreatePreview(Parent: GuiObject, WireType: Types.PortType): WireInstance
	local PreviewWire = Wire.Create({
		WireId = "Preview",
		WireType = WireType,
		Parent = Parent,
	})

	for _, Segment in PreviewWire.Frame:GetChildren() do
		if Segment:IsA("Frame") then
			Segment.BackgroundColor3 = Theme.Colors.WirePreview
			Segment.ZIndex = Theme.ZIndex.WirePreview
		end
	end

	PreviewWire.Frame.ZIndex = Theme.ZIndex.WirePreview

	return PreviewWire
end

return Wire