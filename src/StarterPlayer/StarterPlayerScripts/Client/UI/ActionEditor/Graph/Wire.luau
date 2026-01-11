--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local Wire = {}

local MIN_SEGMENTS = 10
local MAX_SEGMENTS = 140

local PIXELS_PER_SEGMENT_NEAR = 10
local PIXELS_PER_SEGMENT_FAR = 18

local DISTANCE_NEAR = 0
local DISTANCE_FAR = 500

local CURVATURE_SEGMENT_BONUS = 0.7

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
	SetCanvasPositions: (StartPosition: Vector2, EndPosition: Vector2) -> (),
	SetHighlighted: (Highlighted: boolean) -> (),
	SetSelected: (Selected: boolean) -> (),
	Destroy: () -> (),
}

local function Lerp(NumberA: number, NumberB: number, Alpha: number): number
	return NumberA + (NumberB - NumberA) * Alpha
end

local function CubicBezier(P0: Vector2, P1: Vector2, P2: Vector2, P3: Vector2, T: number): Vector2
	local OneMinusT = 1 - T
	local OneMinusT2 = OneMinusT * OneMinusT
	local OneMinusT3 = OneMinusT2 * OneMinusT
	local T2 = T * T
	local T3 = T2 * T

	return (P0 * OneMinusT3) + (P1 * 3 * OneMinusT2 * T) + (P2 * 3 * OneMinusT * T2) + (P3 * T3)
end

local function ComputeSegmentCount(Distance: number, CurvatureFactor: number): number
	local DistanceAlpha = 0
	if DISTANCE_FAR > DISTANCE_NEAR then
		DistanceAlpha = (Distance - DISTANCE_NEAR) / (DISTANCE_FAR - DISTANCE_NEAR)
	end
	DistanceAlpha = math.clamp(DistanceAlpha, 0, 1)

	local PixelsPerSegment = Lerp(PIXELS_PER_SEGMENT_NEAR, PIXELS_PER_SEGMENT_FAR, DistanceAlpha)

	local BaseSegments = math.floor((Distance / PixelsPerSegment) + 0.5)
	local CurvatureMultiplier = 1 + (CurvatureFactor * CURVATURE_SEGMENT_BONUS)
	local ScaledSegments = math.floor((BaseSegments * CurvatureMultiplier) + 0.5)

	return math.clamp(ScaledSegments, MIN_SEGMENTS, MAX_SEGMENTS)
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
	local ActiveSegmentCount = 0

	local function CreateSegment(Index: number): (Frame, TextButton)
		local Segment = Instance.new("Frame")
		Segment.Name = "Segment_" .. Index
		Segment.BackgroundColor3 = WireColor
		Segment.BorderSizePixel = 0
		Segment.AnchorPoint = Vector2.new(0, 0.5)
		Segment.ZIndex = Theme.ZIndex.Wire
		Segment.Visible = false
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
				for SegmentIndex = 1, ActiveSegmentCount do
					Segments[SegmentIndex].BackgroundColor3 = Theme.Colors.BorderFocus
				end
			end
		end)

		ClickDetector.MouseLeave:Connect(function()
			if not IsHighlighted then
				for SegmentIndex = 1, ActiveSegmentCount do
					Segments[SegmentIndex].BackgroundColor3 = WireColor
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

		return Segment, ClickDetector
	end

	local function EnsureSegments(RequiredCount: number)
		local CurrentCount = #Segments
		if RequiredCount > CurrentCount then
			for Index = CurrentCount + 1, RequiredCount do
				local Segment, ClickDetector = CreateSegment(Index)
				table.insert(Segments, Segment)
				table.insert(ClickDetectors, ClickDetector)
			end
		end

		ActiveSegmentCount = RequiredCount

		for Index = 1, #Segments do
			local Segment = Segments[Index]
			Segment.Visible = Index <= ActiveSegmentCount
		end
	end

	EnsureSegments(MIN_SEGMENTS)

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

	local function RenderBezier(P0: Vector2, P3: Vector2)
		local Delta = P3 - P0
		local Distance = Delta.Magnitude

		local DistanceStart = 60
		local DistanceFull = 260

		local Normalized = 0
		if DistanceFull > DistanceStart then
			Normalized = (Distance - DistanceStart) / (DistanceFull - DistanceStart)
		end
		Normalized = math.clamp(Normalized, 0, 1)

		local MaxCurvature = WIRE_CURVATURE
		local ControlOffset = MaxCurvature * Normalized

		local CurvatureFactor = 0
		if MaxCurvature > 0 then
			CurvatureFactor = math.clamp(ControlOffset / MaxCurvature, 0, 1)
		end

		local SegmentCount = ComputeSegmentCount(Distance, CurvatureFactor)
		EnsureSegments(SegmentCount)

		local P1 = P0 + Vector2.new(ControlOffset, 0)
		local P2 = P3 - Vector2.new(ControlOffset, 0)

		for Index = 1, SegmentCount do
			local Segment = Segments[Index]

			local T0 = (Index - 1) / SegmentCount
			local T1 = Index / SegmentCount

			local Point0 = CubicBezier(P0, P1, P2, P3, T0)
			local Point1 = CubicBezier(P0, P1, P2, P3, T1)

			local SegmentDelta = Point1 - Point0
			local Length = SegmentDelta.Magnitude
			local Angle = math.atan2(SegmentDelta.Y, SegmentDelta.X)

			Segment.Size = UDim2.fromOffset(math.max(Length + 2, 4), Theme.Sizes.WireThickness)
			Segment.Position = UDim2.fromOffset(Point0.X, Point0.Y)
			Segment.Rotation = math.deg(Angle)
		end
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

		RenderBezier(AdjustedStart, AdjustedEnd)
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

	function Instance.SetCanvasPositions(CanvasStart: Vector2, CanvasEnd: Vector2)
		RenderBezier(CanvasStart, CanvasEnd)
	end

	function Instance.SetHighlighted(Highlighted: boolean)
		IsHighlighted = Highlighted
		local NewThickness = if Highlighted then Theme.Sizes.WireThicknessHover else Theme.Sizes.WireThickness
		local NewColor = if Highlighted then Theme.Colors.BorderFocus else WireColor

		for Index = 1, ActiveSegmentCount do
			local Segment = Segments[Index]
			Segment.Size = UDim2.fromOffset(Segment.Size.X.Offset, NewThickness)
			Segment.BackgroundColor3 = NewColor
		end
	end

	function Instance.SetSelected(Selected: boolean)
		local NewColor = if Selected then Theme.Colors.Primary else WireColor

		for Index = 1, ActiveSegmentCount do
			Segments[Index].BackgroundColor3 = NewColor
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
