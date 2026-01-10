--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local Packets = require(Shared.Network.Packets)
local CombatTypes = require(Shared.Types.CombatTypes)

type Block = CombatTypes.Block
type ExecutionContext = CombatTypes.ExecutionContext
type HandlerResult = CombatTypes.HandlerResult

local IsServer = RunService:IsServer()

local HitboxHandler = {}

local CharactersFolder = workspace:FindFirstChild("Characters")

local function DetectTargets(Origin: CFrame, Size: Vector3, Exclude: Model): { Model }
	local Results: { Model } = {}

	if not CharactersFolder then
		return Results
	end

	local OverlapParams = OverlapParams.new()
	OverlapParams.FilterType = Enum.RaycastFilterType.Include
	OverlapParams.FilterDescendantsInstances = { CharactersFolder }

	local Parts = workspace:GetPartBoundsInBox(Origin, Size, OverlapParams)

	for _, Part in Parts do
		if Part.Name ~= "HumanoidRootPart" then
			continue
		end

		local Character = Part.Parent :: Model
		if Character == Exclude then
			continue
		end

		if not Character:FindFirstChildOfClass("Humanoid") then
			continue
		end

		if table.find(Results, Character) then
			continue
		end

		table.insert(Results, Character)
	end

	return Results
end

function HitboxHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local OffsetX = Block.X or 0
	local OffsetY = Block.Y or 0
	local OffsetZ = Block.Z or 4
	local SizeX = Block.SizeX or 6
	local SizeY = Block.SizeY or 6
	local SizeZ = Block.SizeZ or 6

	local Stun = Block.Stun or 0
	local Damage = (Block.Damage or 0) * Context.Properties.DamageMultiplier
	local AttackType = Block.AttackType or "Melee"
	local Blockable = Block.Blockable ~= false
	local Block360 = Block.Block360 or false
	local CancelEnemy = Block.CancelEnemy ~= false

	local Outputs = Block.Outputs
	local OutputDuration = Outputs and Outputs.Duration

	local Character = Context.Entity.Character
	local RootPart = Character:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not RootPart then
		return nil
	end

	local Offset = Vector3.new(OffsetX, OffsetY, -OffsetZ)
	local Size = Vector3.new(SizeX, SizeY, SizeZ)
	local Origin = RootPart.CFrame * CFrame.new(Offset)

	local Targets = DetectTargets(Origin, Size, Character)

	if #Targets > 0 then
		for _, Target in Targets do
			Context.RecordHit(Target, Damage)

			if not IsServer then
				Packets.HitCandidates:Fire(
					Context.SkillDefinition.SkillId,
					Target.Name,
					Damage,
					Stun,
					AttackType,
					Blockable,
					Block360,
					CancelEnemy,
					tick()
				)
			end
		end

		if Outputs and Outputs.OnHit then
			Context.EmitSignal(Outputs.OnHit, OutputDuration)
		end
	else
		Context.EventBus:Publish(Enums.Combat.Hitbox.Missed, {
			Entity = Context.Entity,
			SkillId = Context.SkillDefinition.SkillId,
		})

		if Outputs and Outputs.OnMiss then
			Context.EmitSignal(Outputs.OnMiss, OutputDuration)
		end
	end

	return nil
end

return HitboxHandler