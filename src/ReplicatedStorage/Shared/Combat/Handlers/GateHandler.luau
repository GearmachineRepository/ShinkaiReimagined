--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ActionTypes = require(Shared.Types.ActionTypes)

type Block = ActionTypes.Block
type ExecutionContext = ActionTypes.ExecutionContext
type HandlerResult = ActionTypes.HandlerResult

local GateHandler = {}

function GateHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local Timeout = Block.Timeout or 0
	local SignalId = Block.SignalInput

	if not SignalId then
		warn("[GateHandler] No signal input connected")
		return nil
	end

	local StartTime = tick()

	if Timeout > 0 then
		while not Context.IsSignalActive(SignalId) do
			if Context.Canceled then
				return { Cancel = true }
			end

			if tick() - StartTime >= Timeout then
				return nil
			end

			task.wait()
		end
	else
		while not Context.IsSignalActive(SignalId) do
			if Context.Canceled then
				return { Cancel = true }
			end

			task.wait()
		end
	end

	return nil
end

return GateHandler