--!strict

local EditorWindow = require(script.Panels.EditorWindow)
local ActionSerializer = require(script.Serialization.ActionSerializer)

export type EditorWindowInstance = EditorWindow.EditorWindowInstance

local ActionEditor = {}

ActionEditor.Create = EditorWindow.Create
ActionEditor.ImportActionData = ActionSerializer.Import
ActionEditor.ExportActionData = ActionSerializer.Export

return ActionEditor