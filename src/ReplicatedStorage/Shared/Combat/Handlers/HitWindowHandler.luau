--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local HitWindowHandler = {}

function HitWindowHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local TimeWindow = Block.Time or 0.3
	local Endlag = Block.Endlag or 0

	local StartTime = tick()

	while tick() - StartTime < TimeWindow do
		if Context.Canceled then
			return { Cancel = true }
		end
		task.wait()
	end

	local HadHit = Context.HadHitInWindow(TimeWindow + 0.1)

	if Endlag > 0 then
		task.wait(Endlag)
	end

	if HadHit then
		return { FlowPort = "OnHit" }
	else
		return { FlowPort = "OnMiss" }
	end
end

return HitWindowHandler