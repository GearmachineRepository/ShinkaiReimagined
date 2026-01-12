--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockDefinitions = require(Shared.Combat.BlockDefinitions)
local ActionTypes = require(Shared.Types.ActionTypes)

export type PortDirection = BlockDefinitions.PortDirection
export type PortType = BlockDefinitions.PortType
export type PortDefinition = BlockDefinitions.PortDefinition
export type PropertyType = BlockDefinitions.PropertyType
export type PropertyDefinition = BlockDefinitions.PropertyDefinition
export type NodeDefinition = BlockDefinitions.BlockDefinition

export type NodeInstance = {
	NodeId: string,
	BlockType: string,
	Position: Vector2,
	Properties: { [string]: any },
	Block: ActionTypes.Block?,
}

export type WireInstance = {
	WireId: string,
	FromNodeId: string,
	FromPortName: string,
	ToNodeId: string,
	ToPortName: string,
	WireType: PortType,
	ValueType: string?,
}

export type CommentData = {
	CommentId: string,
	Title: string,
	Text: string,
	Color: Color3,
	Position: Vector2,
	Size: Vector2,
}

export type BranchData = {
	BranchId: string,
	BranchName: string,
	IsEntry: boolean,
	Nodes: { NodeInstance },
	Wires: { WireInstance },
	Comments: { CommentData }?,
	Position: Vector2,
	Collapsed: boolean?,
}

export type EditorState = {
	ActionId: string,
	DisplayName: string,
	Branches: { [string]: BranchData },
	SelectedNodeId: string?,
	SelectedBranchId: string?,
	SelectedWireId: string?,
	SelectedCommentId: string?,
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