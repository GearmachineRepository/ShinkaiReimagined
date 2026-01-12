--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local Combat = require(Shared.Combat)
local Packets = require(Shared.Network.Packets)

local Trove = Packages.Trove
local Signal = Packages.Signal

local ActionExecutor = Combat.ActionExecutor
local ActionValidator = Combat.ActionValidator
local ActionRegistry = Combat.ActionRegistry

local PlayerActionManager = {}

PlayerActionManager.Dependencies = {}

PlayerActionManager.ActionCreated = Signal.new()
PlayerActionManager.ActionUpdated = Signal.new()
PlayerActionManager.ActionDeleted = Signal.new()

local ServiceTrove: typeof(Trove.new()) = nil :: any
local PlayerActions: { [Player]: { [string]: any } } = {}

local MAX_PLAYER_ActionS = 20

local function MakeActionId(Player: Player, BaseName: string): string
    return "Player_" .. Player.UserId .. "_" .. BaseName
end

local function ExtractBaseName(ActionId: string): string
    return string.gsub(ActionId, "^Player_%d+_", "")
end

local function IsPlayerActionId(ActionId: string, Player: Player): boolean
    local Pattern = "^Player_" .. Player.UserId .. "_"
    return string.match(ActionId, Pattern) ~= nil
end

function PlayerActionManager.Init()
    ServiceTrove = Trove.new()
end

function PlayerActionManager.Start()
    ServiceTrove:Connect(Players.PlayerRemoving, function(Player: Player)
        PlayerActionManager.Cleanup(Player)
    end)

    ServiceTrove:Connect(Packets.PlayerActionCreate.OnServerEvent :: any, function(Player: Player, RawAction: any)
        local Success, Result = PlayerActionManager.CreateAction(Player, RawAction)
        Packets.PlayerActionCreateResult:FireClient(Player, Success, Result or "Unknown")

        if Success then
            local Action = PlayerActionManager.GetAction(Player, Result or "Unknown")
            if Action then
                Packets.PlayerActionAdded:FireClient(Player, Result or "Unknown", Action)
            end
        end
    end)

    ServiceTrove:Connect(Packets.PlayerActionUpdate.OnServerEvent :: any, function(Player: Player, RawAction: any)
        local Success, Result = PlayerActionManager.UpdateAction(Player, RawAction)
        Packets.PlayerActionUpdateResult:FireClient(Player, Success, Result or "Unknown")

        if Success then
            local Action = PlayerActionManager.GetAction(Player, Result or "Unknown")
            if Action then
                Packets.PlayerActionAdded:FireClient(Player, Result or "Unknown", Action)
            end
        end
    end)

    ServiceTrove:Connect(Packets.PlayerActionDelete.OnServerEvent :: any, function(Player: Player, ActionId: string)
        local Success = PlayerActionManager.DeleteAction(Player, ActionId)
        local Reason = if Success then ActionId else "NotFound"
        Packets.PlayerActionDeleteResult:FireClient(Player, Success, Reason)

        if Success then
            Packets.PlayerActionRemoved:FireClient(Player, ActionId)
        end
    end)

    ServiceTrove:Connect(Packets.PlayerActionEquip.OnServerEvent :: any, function(Player: Player, ActionId: string)
        local Success = PlayerActionManager.RegisterForExecution(Player, ActionId)
        local Reason = if Success then ActionId else "NotFound"
        Packets.PlayerActionEquipResult:FireClient(Player, Success, Reason)
    end)

    ServiceTrove:Connect(Packets.PlayerActionUnequip.OnServerEvent :: any, function(Player: Player, ActionId: string)
        if PlayerActionManager.CanUseAction(Player, ActionId) then
            PlayerActionManager.UnregisterFromExecution(ActionId)
        end
    end)
end

function PlayerActionManager.Stop()
    for Player in PlayerActions do
        PlayerActionManager.Cleanup(Player)
    end

    ServiceTrove:Destroy()
    table.clear(PlayerActions)
end

function PlayerActionManager.LoadFromData(Player: Player, SavedActions: { any }?)
    if not SavedActions then
        PlayerActions[Player] = {}
        Packets.PlayerActionSync:FireClient(Player, {})
        return
    end

    PlayerActions[Player] = {}

    for _, RawAction in SavedActions do
        local ValidAction = ActionValidator.Validate(RawAction)
        if ValidAction then
            local BaseName = ValidAction.DisplayName or ValidAction.ActionId or "Unnamed"
            local ActionId = MakeActionId(Player, BaseName)
            ValidAction.ActionId = ActionId
            ValidAction.OwnerUserId = Player.UserId
            PlayerActions[Player][ActionId] = ValidAction
        end
    end

    Packets.PlayerActionSync:FireClient(Player, PlayerActions[Player])
end

function PlayerActionManager.SaveToData(Player: Player): { any }
    local Actions = PlayerActions[Player]
    if not Actions then
        return {}
    end

    local SaveData = {}
    for _, Action in Actions do
        local CleanAction = table.clone(Action)
        CleanAction.ActionId = ExtractBaseName(CleanAction.ActionId)
        CleanAction.OwnerUserId = nil
        CleanAction.IsPlayerMade = nil
        table.insert(SaveData, CleanAction)
    end

    return SaveData
end

function PlayerActionManager.CreateAction(Player: Player, RawAction: any): (boolean, string?)
    local Actions = PlayerActions[Player]
    if not Actions then
        Actions = {}
        PlayerActions[Player] = Actions
    end

    local Count = 0
    for _ in Actions do
        Count = Count + 1
    end

    if Count >= MAX_PLAYER_ActionS then
        return false, "TooManyActions"
    end

    local ValidAction = ActionValidator.Validate(RawAction)
    if not ValidAction then
        return false, "InvalidAction"
    end

    local BaseName = ValidAction.DisplayName or "Unnamed"
    local ActionId = MakeActionId(Player, BaseName)

    if Actions[ActionId] then
        return false, "ActionExists"
    end

    ValidAction.ActionId = ActionId
    ValidAction.OwnerUserId = Player.UserId

    Actions[ActionId] = ValidAction

    ActionExecutor.ClearCache(ActionId)

    PlayerActionManager.ActionCreated:Fire(Player, ActionId, ValidAction)

    return true, ActionId
end

function PlayerActionManager.UpdateAction(Player: Player, RawAction: any): (boolean, string?)
    local Actions = PlayerActions[Player]
    if not Actions then
        return false, "NoActions"
    end

    local ValidAction = ActionValidator.Validate(RawAction)
    if not ValidAction then
        return false, "InvalidAction"
    end

    local ActionId = ValidAction.ActionId

    if not ActionId or ActionId == "" then
        return false, "NoActionId"
    end

    if not IsPlayerActionId(ActionId, Player) then
        return false, "InvalidActionId"
    end

    if not Actions[ActionId] then
        return false, "ActionNotFound"
    end

    ValidAction.ActionId = ActionId
    ValidAction.OwnerUserId = Player.UserId

    Actions[ActionId] = ValidAction

    ActionExecutor.ClearCache(ActionId)

    if ActionRegistry.Has(ActionId) then
        ActionRegistry.Unregister(ActionId)
        ActionRegistry.Register(ValidAction)
    end

    PlayerActionManager.ActionUpdated:Fire(Player, ActionId, ValidAction)

    return true, ActionId
end

function PlayerActionManager.DeleteAction(Player: Player, ActionId: string): boolean
    local Actions = PlayerActions[Player]
    if not Actions then
        return false
    end

    if not Actions[ActionId] then
        return false
    end

    if ActionRegistry.Has(ActionId) then
        ActionRegistry.Unregister(ActionId)
    end

    Actions[ActionId] = nil

    ActionExecutor.ClearCache(ActionId)

    PlayerActionManager.ActionDeleted:Fire(Player, ActionId)

    return true
end

function PlayerActionManager.GetAction(Player: Player, ActionId: string): any?
    local Actions = PlayerActions[Player]
    if not Actions then
        return nil
    end
    return Actions[ActionId]
end

function PlayerActionManager.GetAllActions(Player: Player): { [string]: any }
    return PlayerActions[Player] or {}
end

function PlayerActionManager.GetActionCount(Player: Player): number
    local Actions = PlayerActions[Player]
    if not Actions then
        return 0
    end

    local Count = 0
    for _ in Actions do
        Count = Count + 1
    end
    return Count
end

function PlayerActionManager.CanUseAction(Player: Player, ActionId: string): boolean
    if not string.match(ActionId, "^Player_%d+_") then
        return true
    end

    local OwnerUserId = tonumber(string.match(ActionId, "^Player_(%d+)_"))
    return OwnerUserId == Player.UserId
end

function PlayerActionManager.RegisterForExecution(Player: Player, ActionId: string): boolean
    local Action = PlayerActionManager.GetAction(Player, ActionId)
    if not Action then
        return false
    end

    if ActionRegistry.Has(ActionId) then
        return true
    end

    ActionRegistry.Register(Action)
    return true
end

function PlayerActionManager.UnregisterFromExecution(ActionId: string): boolean
    if not ActionRegistry.Has(ActionId) then
        return false
    end

    ActionRegistry.Unregister(ActionId)
    return true
end

function PlayerActionManager.Cleanup(Player: Player)
    local Actions = PlayerActions[Player]
    if Actions then
        for ActionId in Actions do
            if ActionRegistry.Has(ActionId) then
                ActionRegistry.Unregister(ActionId)
            end
        end
    end

    PlayerActions[Player] = nil
end

function PlayerActionManager.IsPlayerAction(ActionId: string): boolean
    return string.match(ActionId, "^Player_%d+_") ~= nil
end

function PlayerActionManager.GetOwnerUserId(ActionId: string): number?
    local Match = string.match(ActionId, "^Player_(%d+)_")
    if Match then
        return tonumber(Match)
    end
    return nil
end

return PlayerActionManager