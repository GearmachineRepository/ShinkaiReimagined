--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local ConditionHandler = {}

local function CheckCondition(Check: string, Value: number, Context: ExecutionContext): boolean
	local Entity = Context.Entity
	local Character = Entity.Character
	local Humanoid = Entity.Humanoid

	if Check == "IsGrounded" then
		return Humanoid.FloorMaterial ~= Enum.Material.Air

	elseif Check == "IsAirborne" then
		return Humanoid.FloorMaterial == Enum.Material.Air

	elseif Check == "HasTarget" then
		local LastTarget = Context.GetLastHitTarget()
		return LastTarget ~= nil

	elseif Check == "IsBlocking" then
		local Blocking = Character:GetAttribute("IsBlocking")
		return Blocking == true

	elseif Check == "IsStunned" then
		local Stunned = Character:GetAttribute("IsStunned")
		return Stunned == true

	elseif Check == "HealthAbove" then
		local MaxHealth = Humanoid.MaxHealth
		local CurrentHealth = Humanoid.Health
		local Percentage = (CurrentHealth / MaxHealth) * 100
		return Percentage > Value

	elseif Check == "HealthBelow" then
		local MaxHealth = Humanoid.MaxHealth
		local CurrentHealth = Humanoid.Health
		local Percentage = (CurrentHealth / MaxHealth) * 100
		return Percentage < Value

	elseif Check == "TargetInRange" then
		local LastTarget = Context.GetLastHitTarget()
		if not LastTarget then
			return false
		end
		local TargetRoot = LastTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
		local SelfRoot = Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not TargetRoot or not SelfRoot then
			return false
		end
		local Distance = (TargetRoot.Position - SelfRoot.Position).Magnitude
		return Distance <= Value
	end

	return false
end

function ConditionHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local Check = Block.Check or "IsGrounded"
	local Value = Block.Value or 50

	local Result = CheckCondition(Check, Value, Context)

	if Result then
		return { FlowPort = "True" }
	else
		return { FlowPort = "False" }
	end
end

return ConditionHandler