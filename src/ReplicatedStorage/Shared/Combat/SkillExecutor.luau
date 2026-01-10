--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local CombatTypes = require(Shared.Types.CombatTypes)
local Handlers = require(script.Parent.Handlers)
local ExecutionContextModule = require(script.Parent.ExecutionContext)

type ExecutionEntity = CombatTypes.ExecutionEntity
type SkillDefinition = CombatTypes.SkillDefinition
type ExecutionContext = CombatTypes.ExecutionContext
type Branch = CombatTypes.Branch
type Block = CombatTypes.Block
type HandlerResult = CombatTypes.HandlerResult

local SkillExecutor = {}

function SkillExecutor.CreateContext(
	Entity: ExecutionEntity,
	SkillDefinition: SkillDefinition,
	EventBus: any
): ExecutionContext
	return ExecutionContextModule.Create(Entity, SkillDefinition, EventBus)
end

function SkillExecutor.Run(ExecutionContext: ExecutionContext)
	local Entity = ExecutionContext.Entity
	local SkillDefinition = ExecutionContext.SkillDefinition
	local EventBus = ExecutionContext.EventBus

	EventBus:Publish(Enums.Combat.Skill.Activated, {
		Entity = Entity,
		SkillId = SkillDefinition.SkillId,
	})

	local EntryBranch = SkillExecutor.GetEntryBranch(SkillDefinition)
	SkillExecutor.RunBranch(EntryBranch, ExecutionContext)

	if ExecutionContext.Canceled then
		EventBus:Publish(Enums.Combat.Skill.Canceled, {
			Entity = Entity,
			SkillId = SkillDefinition.SkillId,
		})
	else
		EventBus:Publish(Enums.Combat.Skill.Completed, {
			Entity = Entity,
			SkillId = SkillDefinition.SkillId,
		})
	end
end

function SkillExecutor.Execute(
	Entity: ExecutionEntity,
	SkillDefinition: SkillDefinition,
	EventBus: any
): ExecutionContext
	local ExecutionContext = SkillExecutor.CreateContext(Entity, SkillDefinition, EventBus)
	SkillExecutor.Run(ExecutionContext)
	return ExecutionContext
end

function SkillExecutor.GetEntryBranch(SkillDefinition: SkillDefinition): Branch
	if SkillDefinition.Timeline then
		return { Timeline = SkillDefinition.Timeline }
	end

	if SkillDefinition.Branches then
		for _, BranchData in SkillDefinition.Branches do
			if BranchData.Entry then
				return BranchData
			end
		end

		local MainBranch = SkillDefinition.Branches["Main"]
		if MainBranch then
			return MainBranch
		end
	end

	return { Timeline = {} }
end

function SkillExecutor.CheckSignalRequirement(Block: Block, Context: ExecutionContext): boolean
	local RequireSignal = Block.RequireSignal
	if not RequireSignal then
		return true
	end

	local RequireAll = Block.RequireAll ~= false

	if type(RequireSignal) == "string" then
		return Context.IsSignalActive(RequireSignal)
	end

	if type(RequireSignal) == "table" then
		local SignalList = RequireSignal :: { string }

		if RequireAll then
			for _, SignalId in SignalList do
				if not Context.IsSignalActive(SignalId) then
					return false
				end
			end
			return true
		else
			for _, SignalId in SignalList do
				if Context.IsSignalActive(SignalId) then
					return true
				end
			end
			return false
		end
	end

	return true
end

function SkillExecutor.RunBranch(BranchData: Branch, ExecutionContext: ExecutionContext)
	local Timeline = BranchData.Timeline
	if not Timeline then
		return
	end

	for _Index, Block in Timeline do
		if ExecutionContext.Canceled then
			break
		end

		if not SkillExecutor.CheckSignalRequirement(Block, ExecutionContext) then
			continue
		end

		local Handler = Handlers.Get(Block.BlockType)
		if not Handler then
			continue
		end

		local Success, Result = pcall(function()
			return Handler.Execute(Block, ExecutionContext)
		end)

		if not Success then
			continue
		end

		local HandlerResult = Result :: HandlerResult?

		if HandlerResult then
			if HandlerResult.JumpToBranch then
				local Branches = ExecutionContext.SkillDefinition.Branches
				local TargetBranch = Branches and Branches[HandlerResult.JumpToBranch]
				if TargetBranch then
					ExecutionContext.EventBus:Publish(Enums.Combat.Skill.BranchChanged, {
						Entity = ExecutionContext.Entity,
						SkillId = ExecutionContext.SkillDefinition.SkillId,
						Branch = HandlerResult.JumpToBranch,
					})
					SkillExecutor.RunBranch(TargetBranch, ExecutionContext)
				end
				return
			end

			if HandlerResult.Cancel then
				ExecutionContext.Cancel()
				return
			end
		end
	end
end

function SkillExecutor.Cancel(ExecutionContext: ExecutionContext)
	if ExecutionContext and not ExecutionContext.Canceled then
		ExecutionContext.Cancel()
	end
end

return SkillExecutor