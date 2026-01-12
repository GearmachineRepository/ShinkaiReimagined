--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local IsServer = RunService:IsServer()

local ModifyHealthHandler = {}

function ModifyHealthHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	if not IsServer then
		return nil
	end

	local Amount = Block.Amount or 0
	local TargetMode = Block.TargetMode or "Self"

	local TargetHumanoid: Humanoid? = nil

	if TargetMode == "Self" then
		TargetHumanoid = Context.Entity and Context.Entity.Humanoid
	elseif TargetMode == "LastHit" then
		local LastTarget = Context.LastHitTarget
		if LastTarget then
			TargetHumanoid = LastTarget:FindFirstChildOfClass("Humanoid")
		end
	end

	if not TargetHumanoid then
		return nil
	end

	if Amount > 0 then
		TargetHumanoid.Health = math.min(TargetHumanoid.MaxHealth, TargetHumanoid.Health + Amount)
	elseif Amount < 0 then
		TargetHumanoid.Health = math.max(0, TargetHumanoid.Health + Amount)
	end

	return nil
end

return ModifyHealthHandler