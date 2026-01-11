--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local IsServer = RunService:IsServer()

local AddHealthHandler = {}

function AddHealthHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
    if not IsServer then
        return nil
    end

    local Amount = Block.Amount or 5
    local Humanoid = Context.Entity.Humanoid

    if not Humanoid then
        return nil
    end

    local Percentage = Amount / 100
    local Delta = Humanoid.MaxHealth * Percentage

    if Delta > 0 then
        Humanoid.Health = math.min(Humanoid.MaxHealth, Humanoid.Health + Delta)
    else
        Humanoid.Health = math.max(1, Humanoid.Health + Delta)
    end

    return nil
end

return AddHealthHandler