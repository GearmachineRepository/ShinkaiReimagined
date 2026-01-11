--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)

local WireSnapDetector = {}

local SNAP_RADIUS = 28

export type SnapTarget = {
	NodeId: string,
	PortName: string,
	PortType: Types.PortType,
	Direction: Types.PortDirection,
	WorldPosition: Vector2,
}

export type SnapState = {
	IsSnapped: boolean,
	Target: SnapTarget?,
}

local CurrentSnapState: SnapState = {
	IsSnapped = false,
	Target = nil,
}

local SnapChangedSignal = Signal.new()

WireSnapDetector.SnapChanged = SnapChangedSignal

function WireSnapDetector.FindNearestCompatiblePort(
	MousePosition: Vector2,
	FromNodeId: string,
	FromPortType: Types.PortType,
	FromDirection: Types.PortDirection,
	PortDataList: { {
		NodeId: string,
		PortName: string,
		PortType: Types.PortType,
		Direction: Types.PortDirection,
		WorldPosition: Vector2,
	} }
): SnapTarget?
	local NearestTarget: SnapTarget? = nil
	local NearestDistance = SNAP_RADIUS

	for _, PortData in PortDataList do
		if PortData.NodeId == FromNodeId then
			continue
		end

		if PortData.Direction == FromDirection then
			continue
		end

		if PortData.PortType ~= FromPortType then
			continue
		end

		local Distance = (MousePosition - PortData.WorldPosition).Magnitude

		if Distance < NearestDistance then
			NearestDistance = Distance
			NearestTarget = {
				NodeId = PortData.NodeId,
				PortName = PortData.PortName,
				PortType = PortData.PortType,
				Direction = PortData.Direction,
				WorldPosition = PortData.WorldPosition,
			}
		end
	end

	return NearestTarget
end

function WireSnapDetector.UpdateSnapState(NewTarget: SnapTarget?)
	local WasSnapped = CurrentSnapState.IsSnapped
	local OldTarget = CurrentSnapState.Target

	local IsNowSnapped = NewTarget ~= nil
	local TargetChanged = false

	if IsNowSnapped and WasSnapped then
		if OldTarget and NewTarget then
			TargetChanged = NewTarget.NodeId ~= OldTarget.NodeId or NewTarget.PortName ~= OldTarget.PortName
		else
			TargetChanged = true
		end
	elseif IsNowSnapped ~= WasSnapped then
		TargetChanged = true
	end

	CurrentSnapState = {
		IsSnapped = IsNowSnapped,
		Target = NewTarget,
	}

	if TargetChanged then
		SnapChangedSignal:Fire(CurrentSnapState)
	end
end

function WireSnapDetector.GetSnapState(): SnapState
	return CurrentSnapState
end

function WireSnapDetector.ClearSnapState()
	if CurrentSnapState.IsSnapped then
		CurrentSnapState = {
			IsSnapped = false,
			Target = nil,
		}
		SnapChangedSignal:Fire(CurrentSnapState)
	end
end

function WireSnapDetector.GetSnapRadius(): number
	return SNAP_RADIUS
end

return WireSnapDetector