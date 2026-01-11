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
local CURVE_DIRECTION_SMOOTH_RANGE_PIXELS = 80

local FADE_MAX_TRANSPARENCY = 0.85
local FADE_OPAQUE_FRACTION = 0.25
local FADE_GAMMA = 1.8

local GRADIENT_START_COLOR = Color3.new(1, 1, 1)
local GRADIENT_WHITE_FRACTION = 0.18
local GRADIENT_GAMMA = 0.5

local SNAPPED_COLOR = Color3.new(1, 1, 1)
local SNAPPED_COLOR_BLEND = 0.6

local PLUS_SIZE = 14
local PLUS_THICKNESS = 2

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
	SetSnapped: (Snapped: boolean) -> (),
	SetPlusIndicatorVisible: (Visible: boolean) -> (),
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

local function CreatePlusIndicator(Parent: GuiObject, ZIndex: number): Frame
	local PlusContainer = Instance.new("Frame")
	PlusContainer.Name = "PlusIndicator"
	PlusContainer.Size = UDim2.fromOffset(PLUS_SIZE, PLUS_SIZE)
	PlusContainer.BackgroundTransparency = 1
	PlusContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	PlusContainer.ZIndex = ZIndex + 10
	PlusContainer.Visible = false
	PlusContainer.Parent = Parent

	local HorizontalBar = Instance.new("Frame")
	HorizontalBar.Name = "Horizontal"
	HorizontalBar.Size = UDim2.new(1, 0, 0, PLUS_THICKNESS)
	HorizontalBar.Position = UDim2.fromScale(0, 0.5)
	HorizontalBar.AnchorPoint = Vector2.new(0, 0.5)
	HorizontalBar.BackgroundColor3 = Color3.new(1, 1, 1)
	HorizontalBar.BorderSizePixel = 0
	HorizontalBar.ZIndex = ZIndex + 10
	HorizontalBar.Parent = PlusContainer

	local HorizontalCorner = Instance.new("UICorner")
	HorizontalCorner.CornerRadius = UDim.new(0, 1)
	HorizontalCorner.Parent = HorizontalBar

	local VerticalBar = Instance.new("Frame")
	VerticalBar.Name = "Vertical"
	VerticalBar.Size = UDim2.new(0, PLUS_THICKNESS, 1, 0)
	VerticalBar.Position = UDim2.fromScale(0.5, 0)
	VerticalBar.AnchorPoint = Vector2.new(0.5, 0)
	VerticalBar.BackgroundColor3 = Color3.new(1, 1, 1)
	VerticalBar.BorderSizePixel = 0
	VerticalBar.ZIndex = ZIndex + 10
	VerticalBar.Parent = PlusContainer

	local VerticalCorner = Instance.new("UICorner")
	VerticalCorner.CornerRadius = UDim.new(0, 1)
	VerticalCorner.Parent = VerticalBar

	return PlusContainer
end

function Wire.Create(Config: WireConfig): WireInstance
	local IsPreviewWire = Config.WireId == "Preview"
	local WireColor = Theme.GetWireColor(Config.WireType)
	local StartPosition = Vector2.zero
	local EndPosition = Vector2.new(100, 0)
	local IsHighlighted = false
	local FadeEnabled = IsPreviewWire
	local IsSelected = false
	local IsSnapped = false

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

	local PlusIndicator: Frame? = nil
	if IsPreviewWire then
		PlusIndicator = CreatePlusIndicator(Container, Theme.ZIndex.Wire)
	end

	local function SmoothStep(Alpha: number): number
		local Clamped = math.clamp(Alpha, 0, 1)
		return Clamped * Clamped * (3 - 2 * Clamped)
	end

	local function ComputeHorizontalDirectionFactor(DeltaX: number, SmoothRangePixels: number): number
		if SmoothRangePixels <= 0 then
			return if DeltaX >= 0 then 1 else -1
		end

		local Normalized = (DeltaX / SmoothRangePixels)
		local Alpha = (math.clamp(Normalized, -1, 1) + 1) * 0.5
		local Smoothed = SmoothStep(Alpha)
		return (Smoothed * 2) - 1
	end

	local function GetSnappedColor(): Color3
		return WireColor:Lerp(SNAPPED_COLOR, SNAPPED_COLOR_BLEND)
	end

	local function ComputeGradientColor(SegmentIndex: number, SegmentCount: number): Color3
		if not IsPreviewWire then
			return WireColor
		end

		if IsSnapped then
			return GetSnappedColor()
		end

		if SegmentCount <= 1 then
			return WireColor
		end

		local Normalized = math.clamp((SegmentIndex - 1) / (SegmentCount - 1), 0, 1)

		if Normalized <= GRADIENT_WHITE_FRACTION then
			return GRADIENT_START_COLOR
		end

		local BlendAlpha = (Normalized - GRADIENT_WHITE_FRACTION) / (1 - GRADIENT_WHITE_FRACTION)
		BlendAlpha = math.clamp(BlendAlpha, 0, 1)

		local ShapedAlpha = BlendAlpha ^ GRADIENT_GAMMA
		return GRADIENT_START_COLOR:Lerp(WireColor, ShapedAlpha)
	end

	local function ComputeFadeTransparency(SegmentIndex: number, SegmentCount: number): number
		if IsSnapped then
			return 0
		end

		if not FadeEnabled then
			return 0
		end

		if SegmentCount <= 1 then
			return 0
		end

		local Normalized = math.clamp(SegmentIndex / SegmentCount, 0, 1)

		if Normalized <= FADE_OPAQUE_FRACTION then
			return 0
		end

		local FadeAlpha = (Normalized - FADE_OPAQUE_FRACTION) / (1 - FADE_OPAQUE_FRACTION)
		FadeAlpha = math.clamp(FadeAlpha, 0, 1)

		local ShapedAlpha = FadeAlpha ^ FADE_GAMMA
		return Lerp(0, FADE_MAX_TRANSPARENCY, ShapedAlpha)
	end

	local function ApplyFade(SegmentCount: number)
		local ShouldApplyGradient = IsPreviewWire and (not IsHighlighted) and (not IsSelected)

		for SegmentIndex = 1, SegmentCount do
			local Segment = Segments[SegmentIndex]
			Segment.BackgroundTransparency = ComputeFadeTransparency(SegmentIndex, SegmentCount)

			if ShouldApplyGradient then
				Segment.BackgroundColor3 = ComputeGradientColor(SegmentIndex, SegmentCount)
			elseif IsSnapped then
				Segment.BackgroundColor3 = GetSnappedColor()
			else
				Segment.BackgroundColor3 = WireColor
			end
		end

		for SegmentIndex = SegmentCount + 1, #Segments do
			local Segment = Segments[SegmentIndex]
			Segment.BackgroundTransparency = 0
			if ShouldApplyGradient then
				Segment.BackgroundColor3 = WireColor
			end
		end
	end

	local function CreateSegment(Index: number): (Frame, TextButton?)
		local Segment = Instance.new("Frame")
		Segment.Name = "Segment_" .. Index
		Segment.BackgroundColor3 = WireColor
		Segment.BorderSizePixel = 0
		Segment.AnchorPoint = Vector2.new(0, 0.5)
		Segment.ZIndex = Theme.ZIndex.Wire
		Segment.Visible = false
		Segment.Parent = Container

		Theme.ApplyCorner(Segment, UDim.new(0.5, 0))

		if IsPreviewWire then
			return Segment, nil
		end

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
				if ClickDetector then
					table.insert(ClickDetectors, ClickDetector)
				end
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

	local function UpdatePlusPosition(CanvasEndPosition: Vector2)
		if PlusIndicator then
			PlusIndicator.Position = UDim2.fromOffset(CanvasEndPosition.X, CanvasEndPosition.Y)
		end
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
		local HorizontalDirectionFactor = ComputeHorizontalDirectionFactor(Delta.X, CURVE_DIRECTION_SMOOTH_RANGE_PIXELS)
		local ControlOffset = if IsPreviewWire then MaxCurvature * Normalized * HorizontalDirectionFactor else MaxCurvature * Normalized

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

		ApplyFade(SegmentCount)
		UpdatePlusPosition(P3)
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

	local WireInstance: WireInstance = {
		Frame = Container,
		WireId = Config.WireId,
		WireType = Config.WireType,
	} :: any

	function WireInstance.SetPositions(NewStartPosition: Vector2, NewEndPosition: Vector2)
		StartPosition = NewStartPosition
		EndPosition = NewEndPosition
		UpdateWire()
	end

	function WireInstance.SetCanvasPositions(CanvasStart: Vector2, CanvasEnd: Vector2)
		RenderBezier(CanvasStart, CanvasEnd)
	end

	function WireInstance.SetHighlighted(Highlighted: boolean)
		IsHighlighted = Highlighted
		local NewThickness = if Highlighted then Theme.Sizes.WireThicknessHover else Theme.Sizes.WireThickness
		local NewColor = if Highlighted then Theme.Colors.BorderFocus else WireColor

		for Index = 1, ActiveSegmentCount do
			local Segment = Segments[Index]
			Segment.Size = UDim2.fromOffset(Segment.Size.X.Offset, NewThickness)
			Segment.BackgroundColor3 = NewColor
		end

		ApplyFade(ActiveSegmentCount)
	end

	function WireInstance.SetSelected(Selected: boolean)
		IsSelected = Selected
		local NewColor = if Selected then Theme.Colors.Primary else WireColor

		for Index = 1, ActiveSegmentCount do
			Segments[Index].BackgroundColor3 = NewColor
		end

		ApplyFade(ActiveSegmentCount)
	end

	function WireInstance.SetSnapped(Snapped: boolean)
		if IsSnapped == Snapped then
			return
		end

		IsSnapped = Snapped

		if PlusIndicator then
			PlusIndicator.Visible = not Snapped
		end

		ApplyFade(ActiveSegmentCount)
	end

	function WireInstance.SetPlusIndicatorVisible(Visible: boolean)
		if PlusIndicator then
			if IsSnapped then
				PlusIndicator.Visible = false
			else
				PlusIndicator.Visible = Visible
			end
		end
	end

	function WireInstance.Destroy()
		for _, Segment in Segments do
			Segment:Destroy()
		end
		table.clear(Segments)
		table.clear(ClickDetectors)

		if PlusIndicator then
			PlusIndicator:Destroy()
		end

		Container:Destroy()
	end

	return WireInstance
end

function Wire.CreatePreview(Parent: GuiObject, WireType: Types.PortType): WireInstance
	local PreviewWire = Wire.Create({
		WireId = "Preview",
		WireType = WireType,
		Parent = Parent,
	})

	PreviewWire.SetPlusIndicatorVisible(true)

	return PreviewWire
end

return Wire