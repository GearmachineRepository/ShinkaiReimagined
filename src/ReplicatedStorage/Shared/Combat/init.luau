--!strict

local Combat = {}

Combat.ActionExecutor = require(script.ActionExecutor)
Combat.ActionRegistry = require(script.ActionRegistry)
Combat.ToolRegistry = require(script.ToolRegistry)
Combat.ExecutionContext = require(script.ExecutionContext)
Combat.Handlers = require(script.Handlers)
Combat.ActionValidator = require(script.ActionValidator)
Combat.BlockDefinitons = require(script.BlockDefinitions)

return Combat