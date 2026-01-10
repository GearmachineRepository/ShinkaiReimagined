--!strict

local EditorWindow = require(script.Panels.EditorWindow)

export type EditorWindowInstance = EditorWindow.EditorWindowInstance

local SkillEditor = {}

SkillEditor.Create = EditorWindow.Create
SkillEditor.ImportSkillData = EditorWindow.ImportSkillData
SkillEditor.ExportSkillData = EditorWindow.ExportSkillData

return SkillEditor