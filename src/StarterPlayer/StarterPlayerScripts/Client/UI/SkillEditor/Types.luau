--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatTypes = require(Shared.Types.CombatTypes)

export type PortDirection = "Input" | "Output"
export type PortType = "Flow" | "Signal"

export type PortDefinition = {
	Name: string,
	Direction: PortDirection,
	PortType: PortType,
	AllowMultiple: boolean?,
}

export type NodeDefinition = {
	BlockType: string,
	DisplayName: string,
	Color: Color3,
	Icon: string?,
	Ports: { PortDefinition },
	Properties: { PropertyDefinition },
}

export type PropertyType = "String" | "Number" | "Boolean" | "Dropdown" | "Vector3" | "AssetId"

export type PropertyDefinition = {
	Key: string,
	Label: string,
	Type: PropertyType,
	Default: any,
	Min: number?,
	Max: number?,
	Options: { string }?,
}

export type NodeInstance = {
	NodeId: string,
	BlockType: string,
	Position: Vector2,
	Properties: { [string]: any },
	Block: CombatTypes.Block?,
}

export type WireInstance = {
	WireId: string,
	FromNodeId: string,
	FromPortName: string,
	ToNodeId: string,
	ToPortName: string,
	WireType: PortType,
}

export type BranchData = {
	BranchId: string,
	BranchName: string,
	IsEntry: boolean,
	Nodes: { NodeInstance },
	Wires: { WireInstance },
	Position: Vector2,
	Collapsed: boolean?,
}

export type EditorState = {
	SkillId: string,
	DisplayName: string,
	Branches: { [string]: BranchData },
	SelectedNodeId: string?,
	SelectedBranchId: string?,
	SelectedWireId: string?,
	CanvasOffset: Vector2,
	CanvasZoom: number,
	IsDirty: boolean,
}

export type DragContext = {
	Target: GuiObject,
	StartPosition: Vector2,
	StartMousePosition: Vector2,
	Offset: Vector2,
	IsDragging: boolean,
	Constraints: {
		MinX: number?,
		MaxX: number?,
		MinY: number?,
		MaxY: number?,
	}?,
}

export type Connection = {
	Disconnect: () -> (),
}

export type StateSubscription<T> = {
	Get: () -> T,
	Set: (Value: T) -> (),
	Subscribe: (Callback: (NewValue: T, OldValue: T) -> ()) -> Connection,
}

return nil