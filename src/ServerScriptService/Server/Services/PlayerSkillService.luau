--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Combat = require(Shared.Combat)
local Packets = require(Shared.Network.Packets)

local Trove = Packages.Trove
local Signal = Packages.Signal

local SkillValidator = Combat.SkillValidator
local SkillRegistry = Combat.SkillRegistry

local PlayerSkillManager = {}

PlayerSkillManager.Dependencies = {}

PlayerSkillManager.SkillCreated = Signal.new()
PlayerSkillManager.SkillUpdated = Signal.new()
PlayerSkillManager.SkillDeleted = Signal.new()

local ServiceTrove: typeof(Trove.new()) = nil :: any
local PlayerSkills: { [Player]: { [string]: any } } = {}

local MAX_PLAYER_SKILLS = 20

local function MakeSkillId(Player: Player, BaseName: string): string
    return "Player_" .. Player.UserId .. "_" .. BaseName
end

local function ExtractBaseName(SkillId: string): string
    return string.gsub(SkillId, "^Player_%d+_", "")
end

function PlayerSkillManager.Init()
    ServiceTrove = Trove.new()
end

function PlayerSkillManager.Start()
    ServiceTrove:Connect(Players.PlayerRemoving, function(Player: Player)
        PlayerSkillManager.Cleanup(Player)
    end)

    ServiceTrove:Connect(Packets.PlayerSkillCreate.OnServerEvent :: any, function(Player: Player, RawSkill: any)
        local Success, Result = PlayerSkillManager.CreateSkill(Player, RawSkill)
        Packets.PlayerSkillCreateResult:FireClient(Player, Success, Result or "Unknown")

        if Success then
            local Skill = PlayerSkillManager.GetSkill(Player, Result or "Unknown")
            if Skill then
                Packets.PlayerSkillAdded:FireClient(Player, Result or "Unknown", Skill)
            end
        end
    end)

    ServiceTrove:Connect(Packets.PlayerSkillUpdate.OnServerEvent :: any, function(Player: Player, RawSkill: any)
        local Success, Result = PlayerSkillManager.UpdateSkill(Player, RawSkill)
        Packets.PlayerSkillUpdateResult:FireClient(Player, Success, Result or "Unknown")
    end)

    ServiceTrove:Connect(Packets.PlayerSkillDelete.OnServerEvent :: any, function(Player: Player, SkillId: string)
        local Success = PlayerSkillManager.DeleteSkill(Player, SkillId)
        local Reason = if Success then SkillId else "NotFound"
        Packets.PlayerSkillDeleteResult:FireClient(Player, Success, Reason)

        if Success then
            Packets.PlayerSkillRemoved:FireClient(Player, SkillId)
        end
    end)

    ServiceTrove:Connect(Packets.PlayerSkillEquip.OnServerEvent :: any, function(Player: Player, SkillId: string)
        local Success = PlayerSkillManager.RegisterForExecution(Player, SkillId)
        local Reason = if Success then SkillId else "NotFound"
        Packets.PlayerSkillEquipResult:FireClient(Player, Success, Reason)
    end)

    ServiceTrove:Connect(Packets.PlayerSkillUnequip.OnServerEvent :: any, function(Player: Player, SkillId: string)
        if PlayerSkillManager.CanUseSkill(Player, SkillId) then
            PlayerSkillManager.UnregisterFromExecution(SkillId)
        end
    end)
end

function PlayerSkillManager.Stop()
    for Player in PlayerSkills do
        PlayerSkillManager.Cleanup(Player)
    end

    ServiceTrove:Destroy()
    table.clear(PlayerSkills)
end

function PlayerSkillManager.LoadFromData(Player: Player, SavedSkills: { any }?)
    if not SavedSkills then
        PlayerSkills[Player] = {}
        Packets.PlayerSkillSync:FireClient(Player, {})
        return
    end

    PlayerSkills[Player] = {}

    for _, RawSkill in SavedSkills do
        local ValidSkill = SkillValidator.Validate(RawSkill)
        if ValidSkill then
            local SkillId = MakeSkillId(Player, ValidSkill.SkillId)
            ValidSkill.SkillId = SkillId
            ValidSkill.OwnerUserId = Player.UserId
            PlayerSkills[Player][SkillId] = ValidSkill
        end
    end

    Packets.PlayerSkillSync:FireClient(Player, PlayerSkills[Player])
end

function PlayerSkillManager.SaveToData(Player: Player): { any }
    local Skills = PlayerSkills[Player]
    if not Skills then
        return {}
    end

    local SaveData = {}
    for _, Skill in Skills do
        local CleanSkill = table.clone(Skill)
        CleanSkill.SkillId = ExtractBaseName(CleanSkill.SkillId)
        CleanSkill.OwnerUserId = nil
        CleanSkill.IsPlayerMade = nil
        table.insert(SaveData, CleanSkill)
    end

    return SaveData
end

function PlayerSkillManager.CreateSkill(Player: Player, RawSkill: any): (boolean, string?)
    local Skills = PlayerSkills[Player]
    if not Skills then
        Skills = {}
        PlayerSkills[Player] = Skills
    end

    local Count = 0
    for _ in Skills do
        Count = Count + 1
    end

    if Count >= MAX_PLAYER_SKILLS then
        return false, "TooManySkills"
    end

    local ValidSkill = SkillValidator.Validate(RawSkill)
    if not ValidSkill then
        return false, "InvalidSkill"
    end

    local SkillId = MakeSkillId(Player, ValidSkill.SkillId)

    if Skills[SkillId] then
        return false, "SkillExists"
    end

    ValidSkill.SkillId = SkillId
    ValidSkill.OwnerUserId = Player.UserId

    Skills[SkillId] = ValidSkill

    PlayerSkillManager.SkillCreated:Fire(Player, SkillId, ValidSkill)

    return true, SkillId
end

function PlayerSkillManager.UpdateSkill(Player: Player, RawSkill: any): (boolean, string?)
    local Skills = PlayerSkills[Player]
    if not Skills then
        return false, "NoSkills"
    end

    local ValidSkill = SkillValidator.Validate(RawSkill)
    if not ValidSkill then
        return false, "InvalidSkill"
    end

    local SkillId = MakeSkillId(Player, ValidSkill.SkillId)

    if not Skills[SkillId] then
        return false, "SkillNotFound"
    end

    ValidSkill.SkillId = SkillId
    ValidSkill.OwnerUserId = Player.UserId

    Skills[SkillId] = ValidSkill

    if SkillRegistry.Has(SkillId) then
        SkillRegistry.Unregister(SkillId)
        SkillRegistry.Register(ValidSkill)
    end

    PlayerSkillManager.SkillUpdated:Fire(Player, SkillId, ValidSkill)

    return true, SkillId
end

function PlayerSkillManager.DeleteSkill(Player: Player, SkillId: string): boolean
    local Skills = PlayerSkills[Player]
    if not Skills then
        return false
    end

    if not Skills[SkillId] then
        return false
    end

    if SkillRegistry.Has(SkillId) then
        SkillRegistry.Unregister(SkillId)
    end

    Skills[SkillId] = nil

    PlayerSkillManager.SkillDeleted:Fire(Player, SkillId)

    return true
end

function PlayerSkillManager.GetSkill(Player: Player, SkillId: string): any?
    local Skills = PlayerSkills[Player]
    if not Skills then
        return nil
    end
    return Skills[SkillId]
end

function PlayerSkillManager.GetAllSkills(Player: Player): { [string]: any }
    return PlayerSkills[Player] or {}
end

function PlayerSkillManager.GetSkillCount(Player: Player): number
    local Skills = PlayerSkills[Player]
    if not Skills then
        return 0
    end

    local Count = 0
    for _ in Skills do
        Count = Count + 1
    end
    return Count
end

function PlayerSkillManager.CanUseSkill(Player: Player, SkillId: string): boolean
    if not string.match(SkillId, "^Player_%d+_") then
        return true
    end

    local OwnerUserId = tonumber(string.match(SkillId, "^Player_(%d+)_"))
    return OwnerUserId == Player.UserId
end

function PlayerSkillManager.RegisterForExecution(Player: Player, SkillId: string): boolean
    local Skill = PlayerSkillManager.GetSkill(Player, SkillId)
    if not Skill then
        return false
    end

    if SkillRegistry.Has(SkillId) then
        return true
    end

    SkillRegistry.Register(Skill)
    return true
end

function PlayerSkillManager.UnregisterFromExecution(SkillId: string): boolean
    if not SkillRegistry.Has(SkillId) then
        return false
    end

    SkillRegistry.Unregister(SkillId)
    return true
end

function PlayerSkillManager.Cleanup(Player: Player)
    local Skills = PlayerSkills[Player]
    if Skills then
        for SkillId in Skills do
            if SkillRegistry.Has(SkillId) then
                SkillRegistry.Unregister(SkillId)
            end
        end
    end

    PlayerSkills[Player] = nil
end

function PlayerSkillManager.IsPlayerSkill(SkillId: string): boolean
    return string.match(SkillId, "^Player_%d+_") ~= nil
end

function PlayerSkillManager.GetOwnerUserId(SkillId: string): number?
    local Match = string.match(SkillId, "^Player_(%d+)_")
    if Match then
        return tonumber(Match)
    end
    return nil
end

return PlayerSkillManager