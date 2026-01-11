--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local IsServer = RunService:IsServer()

local SoundHandler = {}

function SoundHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
    if IsServer then
        return nil
    end

    local SoundId = Block.SoundId
    if not SoundId or SoundId == "" then
        return nil
    end

    local Volume = Block.Volume or 1
    local Speed = Block.Speed or 1

    local Character = Context.Entity.Character
    local RootPart = Character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not RootPart then
        return nil
    end

    local Sound = Instance.new("Sound")
    Sound.SoundId = SoundId
    Sound.Volume = Volume
    Sound.PlaybackSpeed = Speed
    Sound.Parent = RootPart
    Sound:Play()

    Sound.Ended:Once(function()
        Sound:Destroy()
    end)

    return nil
end

return SoundHandler