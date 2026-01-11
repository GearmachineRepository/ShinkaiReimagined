--!strict

local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Parent.Types)
local NodeRegistry = require(script.Parent.NodeRegistry)
local Node = require(script.Parent.Parent.Graph.Node)

local NodeFactory = {}

function NodeFactory.GenerateNodeId(): string
	return HttpService:GenerateGUID(false)
end

function NodeFactory.CreateFromBlock(Block: Types.NodeInstance, Callbacks: {
	OnSelected: ((NodeId: string) -> ())?,
	OnMoved: ((NodeId: string, Position: Vector2) -> ())?,
	OnPortConnectionStart: ((NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection) -> ())?,
	OnPortConnectionEnd: ((NodeId: string, PortName: string) -> ())?,
	Parent: GuiObject?,
}): Node.NodeInstance?
	local Definition = NodeRegistry.Get(Block.BlockType)
	if not Definition then
		warn("[NodeFactory] Unknown block type:", Block.BlockType)
		return nil
	end

	local InputPorts = NodeRegistry.GetInputPorts(Block.BlockType)
	local OutputPorts = NodeRegistry.GetOutputPorts(Block.BlockType)

	local NodeInstance = Node.Create({
		NodeId = Block.NodeId,
		BlockType = Block.BlockType,
		DisplayName = Definition.DisplayName,
		Color = Definition.Color,
		Position = Block.Position,
		InputPorts = InputPorts,
		OutputPorts = OutputPorts,
		Parent = Callbacks.Parent,
		OnSelected = Callbacks.OnSelected,
		OnMoved = Callbacks.OnMoved,
		OnPortConnectionStart = Callbacks.OnPortConnectionStart,
		OnPortConnectionEnd = Callbacks.OnPortConnectionEnd,
	})

	return NodeInstance
end

function NodeFactory.CreateNodeInstance(BlockType: string, Position: Vector2?): Types.NodeInstance
	local Definition = NodeRegistry.Get(BlockType)

	local Properties: { [string]: any } = {}
	if Definition then
		for _, PropertyDef in Definition.Properties do
			Properties[PropertyDef.Key] = PropertyDef.Default
		end
	end

	return {
		NodeId = NodeFactory.GenerateNodeId(),
		BlockType = BlockType,
		Position = Position or Vector2.zero,
		Properties = Properties,
		Block = nil,
	}
end

function NodeFactory.NodeToBlock(NodeInstance: Types.NodeInstance): { [string]: any }
	local Block: { [string]: any } = {
		BlockType = NodeInstance.BlockType,
		BlockId = NodeInstance.NodeId,
		EditorPosition = {
			X = NodeInstance.Position.X,
			Y = NodeInstance.Position.Y,
		},
	}

	for Key, Value in NodeInstance.Properties do
		Block[Key] = Value
	end

	return Block
end

function NodeFactory.BlockToNode(Block: { [string]: any }, FallbackPosition: Vector2?): Types.NodeInstance
	local BlockType = Block.BlockType :: string
	local Definition = NodeRegistry.Get(BlockType)

	local Properties: { [string]: any } = {}
	if Definition then
		for _, PropertyDef in Definition.Properties do
			local Value = Block[PropertyDef.Key]
			Properties[PropertyDef.Key] = if Value ~= nil then Value else PropertyDef.Default
		end
	end

	local Position = FallbackPosition or Vector2.zero
	if Block.EditorPosition then
		Position = Vector2.new(
			Block.EditorPosition.X or 0,
			Block.EditorPosition.Y or 0
		)
	end

	return {
		NodeId = Block.BlockId or NodeFactory.GenerateNodeId(),
		BlockType = BlockType,
		Position = Position,
		Properties = Properties,
		Block = Block :: any,
	}
end

return NodeFactory