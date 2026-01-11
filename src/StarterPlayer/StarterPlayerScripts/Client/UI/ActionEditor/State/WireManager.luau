--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Signal = Packages.Signal

local Types = require(script.Parent.Parent.Types)
local EditorState = require(script.Parent.EditorState)
local BranchManager = require(script.Parent.BranchManager)
local NodeManager = require(script.Parent.NodeManager)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)

local WireManager = {}

local WireCreatedSignal = Signal.new()
local WireDeletedSignal = Signal.new()
local ConnectionStartedSignal = Signal.new()
local ConnectionEndedSignal = Signal.new()
local ConnectionCanceledSignal = Signal.new()
local WirePositionsUpdatedSignal = Signal.new()

export type ConnectionState = {
	IsConnecting: boolean,
	FromNodeId: string?,
	FromPortName: string?,
	FromPortType: Types.PortType?,
	FromDirection: Types.PortDirection?,
}

local CurrentConnectionState: ConnectionState = {
	IsConnecting = false,
	FromNodeId = nil,
	FromPortName = nil,
	FromPortType = nil,
	FromDirection = nil,
}

function WireManager.Create(
	FromNodeId: string,
	FromPortName: string,
	ToNodeId: string,
	ToPortName: string,
	WireType: Types.PortType
): Types.WireInstance?
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return nil
	end

	for _, ExistingWire in Branch.Wires do
		if ExistingWire.FromNodeId == FromNodeId
			and ExistingWire.FromPortName == FromPortName
			and ExistingWire.ToNodeId == ToNodeId
			and ExistingWire.ToPortName == ToPortName
		then
			return nil
		end
	end

	local WireData: Types.WireInstance = {
		WireId = HttpService:GenerateGUID(false),
		FromNodeId = FromNodeId,
		FromPortName = FromPortName,
		ToNodeId = ToNodeId,
		ToPortName = ToPortName,
		WireType = WireType,
	}

	table.insert(Branch.Wires, WireData)
	EditorState.MarkDirty()
	WireCreatedSignal:Fire(WireData)

	return WireData
end

function WireManager.Delete(WireId: string): boolean
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return false
	end

	for Index, WireData in Branch.Wires do
		if WireData.WireId == WireId then
			local DeletedWireData = WireData
			table.remove(Branch.Wires, Index)
			EditorState.MarkDirty()
			WireDeletedSignal:Fire(WireId, DeletedWireData)
			return true
		end
	end

	return false
end

function WireManager.DeleteByNode(NodeId: string): { string }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	local DeletedWires: { { WireId: string, WireData: Types.WireInstance } } = {}
	local WiresToKeep: { Types.WireInstance } = {}

	for _, WireData in Branch.Wires do
		if WireData.FromNodeId == NodeId or WireData.ToNodeId == NodeId then
			table.insert(DeletedWires, { WireId = WireData.WireId, WireData = WireData })
		else
			table.insert(WiresToKeep, WireData)
		end
	end

	if #DeletedWires > 0 then
		Branch.Wires = WiresToKeep
		EditorState.MarkDirty()

		for _, Deleted in DeletedWires do
			WireDeletedSignal:Fire(Deleted.WireId, Deleted.WireData)
		end
	end

	local DeletedIds: { string } = {}
	for _, Deleted in DeletedWires do
		table.insert(DeletedIds, Deleted.WireId)
	end
	return DeletedIds
end

function WireManager.DeleteByPort(NodeId: string, PortName: string): { string }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	local DeletedWires: { { WireId: string, WireData: Types.WireInstance } } = {}
	local WiresToKeep: { Types.WireInstance } = {}

	for _, WireData in Branch.Wires do
		local MatchesFrom = WireData.FromNodeId == NodeId and WireData.FromPortName == PortName
		local MatchesTo = WireData.ToNodeId == NodeId and WireData.ToPortName == PortName

		if MatchesFrom or MatchesTo then
			table.insert(DeletedWires, { WireId = WireData.WireId, WireData = WireData })
		else
			table.insert(WiresToKeep, WireData)
		end
	end

	if #DeletedWires > 0 then
		Branch.Wires = WiresToKeep
		EditorState.MarkDirty()

		for _, Deleted in DeletedWires do
			WireDeletedSignal:Fire(Deleted.WireId, Deleted.WireData)
		end
	end

	local DeletedIds: { string } = {}
	for _, Deleted in DeletedWires do
		table.insert(DeletedIds, Deleted.WireId)
	end
	return DeletedIds
end

function WireManager.GetById(WireId: string): Types.WireInstance?
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return nil
	end

	for _, WireData in Branch.Wires do
		if WireData.WireId == WireId then
			return WireData
		end
	end

	return nil
end

function WireManager.GetAll(): { Types.WireInstance }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	return Branch.Wires
end

function WireManager.GetByNode(NodeId: string): { Types.WireInstance }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	local Wires: { Types.WireInstance } = {}
	for _, WireData in Branch.Wires do
		if WireData.FromNodeId == NodeId or WireData.ToNodeId == NodeId then
			table.insert(Wires, WireData)
		end
	end

	return Wires
end

function WireManager.GetByPort(NodeId: string, PortName: string): { Types.WireInstance }
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return {}
	end

	local Wires: { Types.WireInstance } = {}
	for _, WireData in Branch.Wires do
		local MatchesFrom = WireData.FromNodeId == NodeId and WireData.FromPortName == PortName
		local MatchesTo = WireData.ToNodeId == NodeId and WireData.ToPortName == PortName

		if MatchesFrom or MatchesTo then
			table.insert(Wires, WireData)
		end
	end

	return Wires
end

function WireManager.IsPortWired(NodeId: string, PortName: string): boolean
	local Wires = WireManager.GetByPort(NodeId, PortName)
	return #Wires > 0
end

function WireManager.WireExists(
	FromNodeId: string,
	FromPortName: string,
	ToNodeId: string,
	ToPortName: string
): boolean
	local Branch = BranchManager.GetCurrent()
	if not Branch then
		return false
	end

	for _, WireData in Branch.Wires do
		if WireData.FromNodeId == FromNodeId
			and WireData.FromPortName == FromPortName
			and WireData.ToNodeId == ToNodeId
			and WireData.ToPortName == ToPortName
		then
			return true
		end
	end

	return false
end

function WireManager.StartConnection(
	NodeId: string,
	PortName: string,
	PortType: Types.PortType,
	Direction: Types.PortDirection
)
	CurrentConnectionState = {
		IsConnecting = true,
		FromNodeId = NodeId,
		FromPortName = PortName,
		FromPortType = PortType,
		FromDirection = Direction,
	}

	ConnectionStartedSignal:Fire(CurrentConnectionState)
end

function WireManager.EndConnection(NodeId: string, PortName: string): Types.WireInstance?
	if not CurrentConnectionState.IsConnecting then
		return nil
	end

	if CurrentConnectionState.FromNodeId == NodeId then
		WireManager.CancelConnection()
		return nil
	end

	local ToNodeData = NodeManager.GetById(NodeId)
	if not ToNodeData then
		WireManager.CancelConnection()
		return nil
	end

	local ToPortDirection: Types.PortDirection? = nil
	local ToPortType: Types.PortType? = nil
	local ToDefinition = NodeRegistry.Get(ToNodeData.BlockType)

	if ToDefinition then
		for _, PortDef in ToDefinition.Ports do
			if PortDef.Name == PortName then
				ToPortDirection = PortDef.Direction
				ToPortType = PortDef.PortType
				break
			end
		end
	end

	if not ToPortDirection then
		WireManager.CancelConnection()
		return nil
	end

	local FromDirection = CurrentConnectionState.FromDirection
	if FromDirection == ToPortDirection then
		WireManager.CancelConnection()
		return nil
	end

	local FromPortType = CurrentConnectionState.FromPortType
	if FromPortType ~= ToPortType then
		WireManager.CancelConnection()
		return nil
	end

	local FromNodeId = CurrentConnectionState.FromNodeId :: string
	local FromPortName = CurrentConnectionState.FromPortName :: string
	local ToNodeId = NodeId
	local ToPortName = PortName

	if FromDirection == "Input" then
		FromNodeId, ToNodeId = ToNodeId, FromNodeId
		FromPortName, ToPortName = ToPortName, FromPortName
	end

	local WireData = WireManager.Create(
		FromNodeId,
		FromPortName,
		ToNodeId,
		ToPortName,
		CurrentConnectionState.FromPortType :: Types.PortType
	)

	WireManager.CancelConnection()
	ConnectionEndedSignal:Fire(WireData)

	return WireData
end

function WireManager.CancelConnection()
	local WasConnecting = CurrentConnectionState.IsConnecting

	CurrentConnectionState = {
		IsConnecting = false,
		FromNodeId = nil,
		FromPortName = nil,
		FromPortType = nil,
		FromDirection = nil,
	}

	if WasConnecting then
		ConnectionCanceledSignal:Fire()
	end
end

function WireManager.IsConnecting(): boolean
	return CurrentConnectionState.IsConnecting
end

function WireManager.GetConnectionState(): ConnectionState
	return CurrentConnectionState
end

function WireManager.RequestPositionUpdate()
	WirePositionsUpdatedSignal:Fire()
end

function WireManager.ValidateConnection(
	FromNodeId: string,
	FromPortName: string,
	ToNodeId: string,
	ToPortName: string
): boolean
	if FromNodeId == ToNodeId then
		return false
	end

	local FromNode = NodeManager.GetById(FromNodeId)
	local ToNode = NodeManager.GetById(ToNodeId)

	if not FromNode or not ToNode then
		return false
	end

	local FromDefinition = NodeRegistry.Get(FromNode.BlockType)
	local ToDefinition = NodeRegistry.Get(ToNode.BlockType)

	if not FromDefinition or not ToDefinition then
		return false
	end

	local FromPort: Types.PortDefinition? = nil
	local ToPort: Types.PortDefinition? = nil

	for _, PortDef in FromDefinition.Ports do
		if PortDef.Name == FromPortName then
			FromPort = PortDef
			break
		end
	end

	for _, PortDef in ToDefinition.Ports do
		if PortDef.Name == ToPortName then
			ToPort = PortDef
			break
		end
	end

	if not FromPort or not ToPort then
		return false
	end

	if FromPort.Direction == ToPort.Direction then
		return false
	end

	if FromPort.PortType ~= ToPort.PortType then
		return false
	end

	return true
end

WireManager.WireCreated = WireCreatedSignal
WireManager.WireDeleted = WireDeletedSignal
WireManager.ConnectionStarted = ConnectionStartedSignal
WireManager.ConnectionEnded = ConnectionEndedSignal
WireManager.ConnectionCanceled = ConnectionCanceledSignal
WireManager.WirePositionsUpdated = WirePositionsUpdatedSignal

return WireManager