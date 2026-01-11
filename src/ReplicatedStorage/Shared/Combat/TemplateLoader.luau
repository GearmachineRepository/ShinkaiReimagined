--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TemplateLoader = {}

export type TemplateEntry = {
	ActionId: string,
	DisplayName: string,
	Description: string?,
	Data: any,
}

local CachedTemplates: { TemplateEntry }? = nil

local TEMPLATE_DESCRIPTIONS: { [string]: string } = {
	SimplePunch = "Basic punch attack using Timeline format",
	DashAttack = "Forward dash with hitbox and hit/miss branching",
	SignalCombo = "Multi-hit combo using OnHit signals",
	AirDive = "Air-only diving attack with landing variations",
	CounterRage = "Counter-based rage mechanic with Timer",
}

local function GetTemplatesFolder(): Folder?
	local Data = ReplicatedStorage:FindFirstChild("Data")
	if not Data then
		return nil
	end

	local Actions = Data:FindFirstChild("Actions")
	if not Actions or not Actions:IsA("Folder") then
		return nil
	end

	return Actions :: Folder
end

function TemplateLoader.GetTemplates(): { TemplateEntry }
	if CachedTemplates then
		return CachedTemplates
	end

	local Templates: { TemplateEntry } = {}
	local Folder = GetTemplatesFolder()

	if not Folder then
		return Templates
	end

	for _, Child in Folder:GetChildren() do
		if not Child:IsA("ModuleScript") then
			continue
		end

		local Success, Data = pcall(require, Child)
		if not Success then
			warn(string.format("[TemplateLoader] Failed to load %s: %s", Child.Name, tostring(Data)))
			continue
		end

		if type(Data) ~= "table" then
			continue
		end

		local ActionId = Data.ActionId or Child.Name
		local DisplayName = Data.DisplayName or ActionId

		table.insert(Templates, {
			ActionId = ActionId,
			DisplayName = DisplayName,
			Description = TEMPLATE_DESCRIPTIONS[ActionId] or nil,
			Data = Data,
		})
	end

	table.sort(Templates, function(EntryA, EntryB)
		return EntryA.DisplayName < EntryB.DisplayName
	end)

	CachedTemplates = Templates
	return Templates
end

function TemplateLoader.GetTemplate(ActionId: string): any?
	local Templates = TemplateLoader.GetTemplates()

	for _, Template in Templates do
		if Template.ActionId == ActionId then
			return Template.Data
		end
	end

	return nil
end

function TemplateLoader.ClearCache()
	CachedTemplates = nil
end

function TemplateLoader.GetTemplateCount(): number
	local Templates = TemplateLoader.GetTemplates()
	return #Templates
end

return TemplateLoader