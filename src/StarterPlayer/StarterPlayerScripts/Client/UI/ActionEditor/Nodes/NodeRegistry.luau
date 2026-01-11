--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockDefinitions = require(Shared.Combat.BlockDefinitions)

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

type BlockDefinition = BlockDefinitions.BlockDefinition

local NodeRegistry = {}

local function ApplyThemeColor(Definition: BlockDefinition): Types.NodeDefinition
    local ThemeColorKey = "Node" .. Definition.Category
    local Color = Theme.Colors[ThemeColorKey] or Definition.Color

    return {
        BlockType = Definition.BlockType,
        Category = Definition.Category,
        DisplayName = Definition.DisplayName,
        Description = Definition.Description,
        Color = Color,
        Ports = Definition.Ports,
        Properties = Definition.Properties,
    }
end

function NodeRegistry.Get(BlockType: string): Types.NodeDefinition?
	local Definition = BlockDefinitions.Get(BlockType)
	if not Definition then
		return nil
	end
	return ApplyThemeColor(Definition)
end

function NodeRegistry.GetAll(): { [string]: Types.NodeDefinition }
	local All = BlockDefinitions.GetAll()
	local Themed: { [string]: Types.NodeDefinition } = {}

	for BlockType, Definition in All do
		Themed[BlockType] = ApplyThemeColor(Definition)
	end

	return Themed
end

function NodeRegistry.GetBlockTypes(): { string }
	return BlockDefinitions.GetBlockTypes()
end

function NodeRegistry.GetInputPorts(BlockType: string): { Types.PortDefinition }
	return BlockDefinitions.GetInputPorts(BlockType)
end

function NodeRegistry.GetOutputPorts(BlockType: string): { Types.PortDefinition }
	return BlockDefinitions.GetOutputPorts(BlockType)
end

function NodeRegistry.GetCategories(): { { Name: string, Types: { string } } }
	return BlockDefinitions.GetCategories()
end

return NodeRegistry