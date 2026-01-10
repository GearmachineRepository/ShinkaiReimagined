--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Packets = require(Shared.Network.Packets)
local Combat = require(Shared.Combat)

local Trove = Packages.Trove
local Signal = Packages.Signal

local SkillValidator = Combat.SkillValidator
local PortSchemas = Combat.PortSchemas

local PlayerSkillController = {}

PlayerSkillController.Dependencies = {}

PlayerSkillController.SkillsLoaded = Signal.new()
PlayerSkillController.SkillAdded = Signal.new()
PlayerSkillController.SkillUpdated = Signal.new()
PlayerSkillController.SkillRemoved = Signal.new()
PlayerSkillController.CreateResult = Signal.new()
PlayerSkillController.UpdateResult = Signal.new()
PlayerSkillController.DeleteResult = Signal.new()
PlayerSkillController.EquipResult = Signal.new()

local ControllerTrove: typeof(Trove.new()) = nil :: any
local CachedSkills: { [string]: any } = {}
local IsLoaded = false

function PlayerSkillController.Init()
    ControllerTrove = Trove.new()
end

function PlayerSkillController.Start()
    ControllerTrove:Connect(Packets.PlayerSkillSync.OnClientEvent :: any, function(Skills: { [string]: any })
        CachedSkills = Skills or {}
        IsLoaded = true
        PlayerSkillController.SkillsLoaded:Fire(CachedSkills)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillAdded.OnClientEvent :: any, function(SkillId: string, SkillData: any)
        CachedSkills[SkillId] = SkillData
        PlayerSkillController.SkillAdded:Fire(SkillId, SkillData)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillRemoved.OnClientEvent :: any, function(SkillId: string)
        CachedSkills[SkillId] = nil
        PlayerSkillController.SkillRemoved:Fire(SkillId)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillCreateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerSkillController.CreateResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillUpdateResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        if Success then
            PlayerSkillController.SkillUpdated:Fire(Result)
        end
        PlayerSkillController.UpdateResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillDeleteResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerSkillController.DeleteResult:Fire(Success, Result)
    end)

    ControllerTrove:Connect(Packets.PlayerSkillEquipResult.OnClientEvent :: any, function(Success: boolean, Result: string)
        PlayerSkillController.EquipResult:Fire(Success, Result)
    end)
end

function PlayerSkillController.Stop()
    ControllerTrove:Destroy()
    table.clear(CachedSkills)
    IsLoaded = false
end

function PlayerSkillController.IsLoaded(): boolean
    return IsLoaded
end

function PlayerSkillController.GetSkill(SkillId: string): any?
    return CachedSkills[SkillId]
end

function PlayerSkillController.GetAllSkills(): { [string]: any }
    return table.clone(CachedSkills)
end

function PlayerSkillController.GetSkillCount(): number
    local Count = 0
    for _ in CachedSkills do
        Count = Count + 1
    end
    return Count
end

function PlayerSkillController.CreateSkill(RawSkill: any): boolean
    local ValidSkill = SkillValidator.Validate(RawSkill)
    if not ValidSkill then
        PlayerSkillController.CreateResult:Fire(false, "InvalidSkill")
        return false
    end

    Packets.PlayerSkillCreate:Fire(RawSkill)
    return true
end

function PlayerSkillController.UpdateSkill(RawSkill: any): boolean
    local ValidSkill = SkillValidator.Validate(RawSkill)
    if not ValidSkill then
        PlayerSkillController.UpdateResult:Fire(false, "InvalidSkill")
        return false
    end

    Packets.PlayerSkillUpdate:Fire(RawSkill)
    return true
end

function PlayerSkillController.DeleteSkill(SkillId: string)
    Packets.PlayerSkillDelete:Fire(SkillId)
end

function PlayerSkillController.EquipSkill(SkillId: string)
    Packets.PlayerSkillEquip:Fire(SkillId)
end

function PlayerSkillController.UnequipSkill(SkillId: string)
    Packets.PlayerSkillUnequip:Fire(SkillId)
end

function PlayerSkillController.ValidateSkill(RawSkill: any): any?
    return SkillValidator.Validate(RawSkill)
end

function PlayerSkillController.ValidateBlock(Block: any): any?
    return SkillValidator.ValidateBlock(Block)
end

function PlayerSkillController.GetPortSchema(BlockType: string): { Outputs: { string } }?
    return PortSchemas[BlockType]
end

function PlayerSkillController.GetAllPortSchemas(): { [string]: { Outputs: { string } } }
    return PortSchemas
end

function PlayerSkillController.GetBlockTypes(): { string }
    local Types = {}
    for BlockType in pairs(PortSchemas) do
        table.insert(Types, BlockType)
    end
    table.sort(Types)
    return Types
end

return PlayerSkillController