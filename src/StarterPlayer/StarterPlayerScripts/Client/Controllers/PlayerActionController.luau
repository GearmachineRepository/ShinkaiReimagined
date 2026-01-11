--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockDefinitions = require(ReplicatedStorage.Shared.Combat.BlockDefinitions)
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)
local Combat = require(Shared.Combat)

local Trove = Packages.Trove
local Signal = Packages.Signal

local ActionValidator = Combat.ActionValidator
local BlockDefinitons = Combat.BlockDefinitons

type BlockDefinition = BlockDefinitions.BlockDefinition

local PlayerActionController = {}

PlayerActionController.Dependencies = {}

PlayerActionController.ActionsLoaded = Signal.new()
PlayerActionController.ActionAdded = Signal.new()
PlayerActionController.ActionUpdated = Signal.new()
PlayerActionController.ActionRemoved = Signal.new()
PlayerActionController.CreateResult = Signal.new()
PlayerActionController.UpdateResult = Signal.new()
PlayerActionController.DeleteResult = Signal.new()
PlayerActionController.EquipResult = Signal.new()

local ControllerTrove: typeof(Trove.new()) = nil :: any
local CachedActions: { [string]: any } = {}
local IsLoaded = false

function PlayerActionController.Init()
    ControllerTrove = Trove.new()
end

function PlayerActionController.Start()
    ControllerTrove:Connect(Packets.PlayerActionSync.OnClientEvent :: any, function(Actions: { [string]: any })
        CachedActions = Actions or {}
        IsLoaded = true
        PlayerActionController.ActionsLoaded:Fire(CachedActions)
    end)

    ControllerTrove:Connect(Packets.PlayerActionAdded.OnClientEvent :: any, function(ActionId: string, ActionData: any)
        CachedActions[ActionId] = ActionData
        PlayerActionController.ActionAdded:Fire(ActionId, ActionData)
    end)

    ControllerTrove:Connect(Packets.PlayerActionRemoved.OnClientEvent :: any, function(ActionId: string)
        CachedActions[ActionId] = nil
        PlayerActionController.ActionRemoved:Fire(ActionId)
    end)

    ControllerTrove:Connect(Packets.PlayerActionCreateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerActionController.CreateResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerActionUpdateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        if Success then
            PlayerActionController.ActionUpdated:Fire(Result)
        end
        PlayerActionController.UpdateResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerActionDeleteResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerActionController.DeleteResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerActionEquipResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerActionController.EquipResult:Fire(Success, Result)
    end)
end

function PlayerActionController.Stop()
    ControllerTrove:Destroy()
    table.clear(CachedActions)
    IsLoaded = false
end

function PlayerActionController.IsLoaded(): boolean
    return IsLoaded
end

function PlayerActionController.GetAction(ActionId: string): any?
    return CachedActions[ActionId]
end

function PlayerActionController.GetAllActions(): { [string]: any }
    return table.clone(CachedActions)
end

function PlayerActionController.GetActionCount(): number
    local Count = 0
    for _ in CachedActions do
        Count = Count + 1
    end
    return Count
end

function PlayerActionController.CreateAction(RawAction: any): boolean
    local ValidAction = ActionValidator.Validate(RawAction)
    if not ValidAction then
        PlayerActionController.CreateResult:Fire(false, "InvalidAction")
        return false
    end

    Packets.PlayerActionCreate:Fire(RawAction)
    return true
end

function PlayerActionController.UpdateAction(RawAction: any): boolean
    local ValidAction = ActionValidator.Validate(RawAction)
    if not ValidAction then
        PlayerActionController.UpdateResult:Fire(false, "InvalidAction")
        return false
    end

    Packets.PlayerActionUpdate:Fire(RawAction)
    return true
end

function PlayerActionController.DeleteAction(ActionId: string)
    Packets.PlayerActionDelete:Fire(ActionId)
end

function PlayerActionController.EquipAction(ActionId: string)
    Packets.PlayerActionEquip:Fire(ActionId)
end

function PlayerActionController.UnequipAction(ActionId: string)
    Packets.PlayerActionUnequip:Fire(ActionId)
end

function PlayerActionController.ValidateAction(RawAction: any): any?
    return ActionValidator.Validate(RawAction)
end

function PlayerActionController.ValidateBlock(Block: any): any?
    return ActionValidator.ValidateBlock(Block)
end

function ActionValidator.GetBlockDefinition(BlockType: string): BlockDefinition?
	return BlockDefinitions.Get(BlockType)
end

function ActionValidator.GetAllBlockDefinitions(): { [string]: BlockDefinition }
	return BlockDefinitions.GetAll()
end

function ActionValidator.GetSignalOutputs(BlockType: string): { string }
	return BlockDefinitions.GetSignalOutputs(BlockType)
end

function PlayerActionController.GetAllBlockDefinitons(): { [string]: BlockDefinition }
    return BlockDefinitons.GetAll()
end

function PlayerActionController.GetBlockTypes(): { string }
    local Types = {}
    for BlockType in pairs(BlockDefinitons) do
        table.insert(Types, BlockType)
    end
    table.sort(Types)
    return Types
end

return PlayerActionController