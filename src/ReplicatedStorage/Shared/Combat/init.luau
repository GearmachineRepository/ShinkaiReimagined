--!strict

local Combat = {}

Combat.Graph = require(script.Graph)
Combat.Runtime = require(script.Runtime)
Combat.Handlers = require(script.Handlers)
Combat.Registries = require(script.Registries)

Combat.BlockDefinitions = require(script.BlockDefinitions)
Combat.ActionValidator = require(script.ActionValidator)
Combat.TimelineConverter = require(script.TimelineConverter)

Combat.ActionExecutor = Combat.Runtime.ActionExecutor
Combat.ActionController = Combat.Runtime.ActionController
Combat.ActionInstance = Combat.Runtime.ActionInstance
Combat.ActionRegistry = Combat.Registries.ActionRegistry
Combat.ToolRegistry = Combat.Registries.ToolRegistry

return Combat