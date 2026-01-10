--!strict

local Combat = {}

Combat.SkillExecutor = require(script.SkillExecutor)
Combat.SkillRegistry = require(script.SkillRegistry)
Combat.ToolRegistry = require(script.ToolRegistry)
Combat.ExecutionContext = require(script.ExecutionContext)
Combat.Handlers = require(script.Handlers)
Combat.SkillValidator = require(script.SkillValidator)
Combat.PortSchemas = require(script.PortSchemas)

return Combat