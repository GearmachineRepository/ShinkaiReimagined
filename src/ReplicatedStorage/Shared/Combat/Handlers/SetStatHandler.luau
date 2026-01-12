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

local SetStatHandler = {}

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

local function GetStatComponent(): any?
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
	local StatComp = Components:FindFirstChild("StatComponent")
	return StatComp and require(StatComp)
end

local function ResolveTargetCharacter(Context: ExecutionContext, TargetMode: string): Model?
	if TargetMode == "Self" then
		return Context.Entity and Context.Entity.Character
	elseif TargetMode == "LastHit" then
		return Context.LastHitTarget
	end
	return nil
end

function SetStatHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	if not IsServer then
		return nil
	end

	local TargetMode = Block.TargetMode or "Self"
	local StatName = Block.Stat or "Health"
	local Mode = Block.Mode or "Set"
	local Value = Block.Value or 0

	local TargetCharacter = ResolveTargetCharacter(Context, TargetMode)
	if not TargetCharacter then
		return nil
	end

	local Ensemble = GetEnsemble()
	local StatComponent = GetStatComponent()
	if not Ensemble or not StatComponent then
		return nil
	end

	local Entity = Ensemble.GetEntity(TargetCharacter)
	if not Entity then
		return nil
	end

	local Stats = StatComponent.From(Entity)
	if not Stats then
		return nil
	end

	if Mode == "Set" then
		Stats.SetStat(StatName, Value)
	elseif Mode == "Add" then
		local Current = Stats.GetStat(StatName) or 0
		Stats.SetStat(StatName, Current + Value)
	elseif Mode == "Multiply" then
		local Current = Stats.GetStat(StatName) or 0
		Stats.SetStat(StatName, Current * Value)
	end

	return nil
end

return SetStatHandler