--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatTypes = require(Shared.Types.CombatTypes)

type Block = CombatTypes.Block
type ExecutionContext = CombatTypes.ExecutionContext
type HandlerResult = CombatTypes.HandlerResult

local SignalHandler = {}

function SignalHandler.Execute(Block: Block, Context: ExecutionContext): HandlerResult?
	local SignalId = Block.SignalId
	if not SignalId then
		return nil
	end

	local ShouldClear = Block.Clear == true
	local Duration = Block.Duration

	if ShouldClear then
		Context.ClearSignal(SignalId)
	else
		Context.EmitSignal(SignalId, Duration)
	end

	return nil
end

return SignalHandler