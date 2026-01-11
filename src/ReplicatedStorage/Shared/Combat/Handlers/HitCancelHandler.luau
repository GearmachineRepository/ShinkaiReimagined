--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local HitCancelHandler = {}

function HitCancelHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local TimeWindow = Block.Time or 0.3
	local Endlag = Block.Endlag or 0
	local Branch = Block.Branch
	local Flip = Block.Flip or false

	local StartTime = tick()

	while tick() - StartTime < TimeWindow do
		if Context.Canceled then
			return { Cancel = true }
		end
		task.wait()
	end

	local HadHit = Context.HadHitInWindow(TimeWindow + 0.1)

	local ShouldTrigger = if Flip then not HadHit else HadHit

	if Endlag > 0 then
		task.wait(Endlag)
	end

	if ShouldTrigger then
		if Branch and Branch ~= "" then
			return { JumpToBranch = Branch }
		end
		return { FlowPort = "OnHit" }
	else
		return { FlowPort = "OnMiss" }
	end
end

return HitCancelHandler