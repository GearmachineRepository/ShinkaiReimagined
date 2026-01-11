--!strict

local EditorWindow = require(script.Panels.EditorWindow)

export type EditorWindowInstance = EditorWindow.EditorWindowInstance

local ActionEditor = {}

ActionEditor.Create = EditorWindow.Create
ActionEditor.ImportActionData = EditorWindow.ImportActionData
ActionEditor.ExportActionData = EditorWindow.ExportActionData

return ActionEditor