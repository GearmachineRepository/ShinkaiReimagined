--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local HitCancelHandler = {}

function HitCancelHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local TimeWindow = Block.Time or 1
	local Flip = Block.Flip or false
	local Endlag = Block.Endlag or 0
	local BranchName = Block.Branch

	local HadHit = Context.HadHitInWindow(TimeWindow)

	local ShouldActivate: boolean
	if Flip then
		ShouldActivate = not HadHit
	else
		ShouldActivate = HadHit
	end

	if ShouldActivate then
		if Endlag > 0 then
			task.wait(Endlag)
		end

		if BranchName then
			return { JumpToBranch = BranchName }
		else
			return { Cancel = true }
		end
	end

	return nil
end

return HitCancelHandler