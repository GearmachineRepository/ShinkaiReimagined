--!strict

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local IsServer = RunService:IsServer()

local SetStateHandler = {}

local function GetEnsemble(): any?
	if not IsServer then
		return nil
	end
	local Server = ServerScriptService:FindFirstChild("Server")
	if not Server then
		return nil
	end
	local EnsembleModule = Server:FindFirstChild("Ensemble")
	return EnsembleModule and require(EnsembleModule)
end

local function GetStateComponent(): any?
	if not IsServer then
		return nil
	end
	local Server = ServerScriptService:FindFirstChild("Server")
	if not Server then
		return nil
	end
	local Components = Server:FindFirstChild("Components")
	if not Components then
		return nil
	end
	local StateComp = Components:FindFirstChild("StateComponent")
	return StateComp and require(StateComp)
end

local function ResolveTargetCharacter(Context: ExecutionContext, TargetMode: string): Model?
	if TargetMode == "Self" then
		return Context.Entity and Context.Entity.Character
	elseif TargetMode == "LastHit" then
		return Context.LastHitTarget
	end
	return nil
end

function SetStateHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	if not IsServer then
		return nil
	end

	local TargetMode = Block.TargetMode or "Self"
	local StateName = Block.State or "Blocking"
	local Active = Block.Active
	if Active == nil then
		Active = true
	end
	local Duration = Block.Duration or 0

	local TargetCharacter = ResolveTargetCharacter(Context, TargetMode)
	if not TargetCharacter then
		return nil
	end

	local Ensemble = GetEnsemble()
	local StateComponent = GetStateComponent()
	if not Ensemble or not StateComponent then
		return nil
	end

	local Entity = Ensemble.GetEntity(TargetCharacter)
	if not Entity then
		return nil
	end

	local States = StateComponent.From(Entity)
	if not States then
		return nil
	end

	States.SetState(StateName, Active)

	if Duration > 0 and Active then
		task.delay(Duration, function()
			if States then
				States.SetState(StateName, false)
			end
		end)
	end

	return nil
end

return SetStateHandler