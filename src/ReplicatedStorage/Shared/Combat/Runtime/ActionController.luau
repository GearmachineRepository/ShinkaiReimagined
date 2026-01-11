--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)
local ActionTypes = require(Shared.Types.ActionTypes)

local ActionInstance = require(script.Parent.ActionInstance)
local ActionExecutor = require(script.Parent.ActionExecutor)

local Signal = Packages.Signal

type ExecutionEntity = ActionTypes.ExecutionEntity
type ActionDefinition = ActionTypes.ActionDefinition
type ActionInstanceHandle = ActionInstance.ActionInstanceHandle

local ActionController = {}

export type ChannelState = {
	Owner: ActionInstanceHandle?,
	Priority: number,
	AcquiredAt: number,
}

export type EntityState = {
	Channels: { [string]: ChannelState },
	Tags: { [string]: boolean },
	ActiveInstances: { ActionInstanceHandle },
}

export type ControllerConfig = {
	Channels: { string }?,
	DefaultPriorities: { [string]: number }?,
}

local DEFAULT_CHANNELS = { "Primary", "Secondary", "Movement", "Utility" }

local DEFAULT_PRIORITIES: { [string]: number } = {
	Primary = 100,
	Secondary = 80,
	Movement = 60,
	Utility = 40,
}

local EntityStates: { [Model]: EntityState } = {}
local ChannelList: { string } = table.clone(DEFAULT_CHANNELS)
local ChannelPriorities: { [string]: number } = table.clone(DEFAULT_PRIORITIES)

ActionController.ActionStarted = Signal.new()
ActionController.ActionEnded = Signal.new()
ActionController.ChannelAcquired = Signal.new()
ActionController.ChannelReleased = Signal.new()
ActionController.TagChanged = Signal.new()

local function GetOrCreateEntityState(Character: Model): EntityState
	if EntityStates[Character] then
		return EntityStates[Character]
	end

	local State: EntityState = {
		Channels = {},
		Tags = {},
		ActiveInstances = {},
	}

	for _, Channel in ChannelList do
		State.Channels[Channel] = {
			Owner = nil,
			Priority = 0,
			AcquiredAt = 0,
		}
	end

	EntityStates[Character] = State
	return State
end

function ActionController.Configure(Config: ControllerConfig)
	if Config.Channels then
		ChannelList = Config.Channels
	end

	if Config.DefaultPriorities then
		for Channel, Priority in Config.DefaultPriorities do
			ChannelPriorities[Channel] = Priority
		end
	end
end

function ActionController.GetChannels(): { string }
	return table.clone(ChannelList)
end

function ActionController.GetDefaultPriority(Channel: string): number
	return ChannelPriorities[Channel] or 50
end

function ActionController.RequestChannel(
	Instance: ActionInstanceHandle,
	Channel: string,
	Priority: number?
): boolean
	local Character = Instance.Entity.Character
	local State = GetOrCreateEntityState(Character)

	local ChannelState = State.Channels[Channel]
	if not ChannelState then
		return false
	end

	local RequestPriority = Priority or ActionController.GetDefaultPriority(Channel)

	if ChannelState.Owner then
		if ChannelState.Priority > RequestPriority then
			return false
		end

		if ChannelState.Priority == RequestPriority then
			if ChannelState.AcquiredAt <= tick() then
				return false
			end
		end

		local PreviousOwner = ChannelState.Owner
		PreviousOwner.ReleaseChannel(Channel)
		PreviousOwner.Cancel()

		ActionController.ChannelReleased:Fire(Character, Channel, PreviousOwner)
	end

	ChannelState.Owner = Instance
	ChannelState.Priority = RequestPriority
	ChannelState.AcquiredAt = tick()

	Instance.AcquireChannel(Channel, RequestPriority)
	ActionController.ChannelAcquired:Fire(Character, Channel, Instance)

	return true
end

function ActionController.ReleaseChannel(
	Instance: ActionInstanceHandle,
	Channel: string
)
	local Character = Instance.Entity.Character
	local State = EntityStates[Character]

	if not State then
		return
	end

	local ChannelState = State.Channels[Channel]
	if not ChannelState then
		return
	end

	if ChannelState.Owner ~= Instance then
		return
	end

	ChannelState.Owner = nil
	ChannelState.Priority = 0
	ChannelState.AcquiredAt = 0

	Instance.ReleaseChannel(Channel)
	ActionController.ChannelReleased:Fire(Character, Channel, Instance)
end

function ActionController.ReleaseAllChannels(Instance: ActionInstanceHandle)
	local Character = Instance.Entity.Character
	local State = EntityStates[Character]

	if not State then
		return
	end

	for Channel, ChannelState in State.Channels do
		if ChannelState.Owner == Instance then
			ChannelState.Owner = nil
			ChannelState.Priority = 0
			ChannelState.AcquiredAt = 0

			Instance.ReleaseChannel(Channel)
			ActionController.ChannelReleased:Fire(Character, Channel, Instance)
		end
	end
end

function ActionController.GetChannelOwner(
	Character: Model,
	Channel: string
): ActionInstanceHandle?
	local State = EntityStates[Character]
	if not State then
		return nil
	end

	local ChannelState = State.Channels[Channel]
	if not ChannelState then
		return nil
	end

	return ChannelState.Owner
end

function ActionController.IsChannelFree(Character: Model, Channel: string): boolean
	return ActionController.GetChannelOwner(Character, Channel) == nil
end

function ActionController.SetTag(Character: Model, Tag: string, Value: boolean)
	local State = GetOrCreateEntityState(Character)
	local OldValue = State.Tags[Tag]

	if OldValue == Value then
		return
	end

	State.Tags[Tag] = Value
	ActionController.TagChanged:Fire(Character, Tag, Value, OldValue)
end

function ActionController.GetTag(Character: Model, Tag: string): boolean
	local State = EntityStates[Character]
	if not State then
		return false
	end

	return State.Tags[Tag] == true
end

function ActionController.GetAllTags(Character: Model): { [string]: boolean }
	local State = EntityStates[Character]
	if not State then
		return {}
	end

	return table.clone(State.Tags)
end

function ActionController.ClearTag(Character: Model, Tag: string)
	ActionController.SetTag(Character, Tag, false)
end

function ActionController.ClearAllTags(Character: Model)
	local State = EntityStates[Character]
	if not State then
		return
	end

	for Tag in State.Tags do
		ActionController.SetTag(Character, Tag, false)
	end
end

function ActionController.HasActiveAction(Character: Model, Channel: string?): boolean
	local State = EntityStates[Character]
	if not State then
		return false
	end

	if Channel then
		local ChannelState = State.Channels[Channel]
		return ChannelState ~= nil and ChannelState.Owner ~= nil
	end

	return #State.ActiveInstances > 0
end

function ActionController.GetActiveInstances(Character: Model): { ActionInstanceHandle }
	local State = EntityStates[Character]
	if not State then
		return {}
	end

	return table.clone(State.ActiveInstances)
end

function ActionController.CancelAllActions(Character: Model, Channel: string?)
	local State = EntityStates[Character]
	if not State then
		return
	end

	if Channel then
		local ChannelState = State.Channels[Channel]
		if ChannelState and ChannelState.Owner then
			ChannelState.Owner.Cancel()
		end
	else
		for _, Instance in State.ActiveInstances do
			Instance.Cancel()
		end
	end
end

function ActionController.StartAction(
	Entity: ExecutionEntity,
	ActionDefinition: ActionDefinition,
	EventBus: any,
	Channel: string?,
	Priority: number?
): ActionInstanceHandle?
	local Instance = ActionExecutor.CreateInstance(Entity, ActionDefinition, EventBus)
	local Character = Entity.Character
	local State = GetOrCreateEntityState(Character)

	if Channel then
		local Acquired = ActionController.RequestChannel(Instance, Channel, Priority)
		if not Acquired then
			Instance.Destroy()
			return nil
		end
	end

	table.insert(State.ActiveInstances, Instance)
	ActionController.ActionStarted:Fire(Character, Instance)

	task.spawn(function()
		ActionExecutor.RunInstance(Instance)

		local InstanceIndex = table.find(State.ActiveInstances, Instance)
		if InstanceIndex then
			table.remove(State.ActiveInstances, InstanceIndex)
		end

		ActionController.ReleaseAllChannels(Instance)
		ActionController.ActionEnded:Fire(Character, Instance)

		Instance.Destroy()
	end)

	return Instance
end

function ActionController.CanStartAction(
	Character: Model,
	Channel: string?,
	Priority: number?
): boolean
	if not Channel then
		return true
	end

	local State = EntityStates[Character]
	if not State then
		return true
	end

	local ChannelState = State.Channels[Channel]
	if not ChannelState then
		return false
	end

	if not ChannelState.Owner then
		return true
	end

	local RequestPriority = Priority or ActionController.GetDefaultPriority(Channel)
	return RequestPriority >= ChannelState.Priority
end

function ActionController.CleanupEntity(Character: Model)
	local State = EntityStates[Character]
	if not State then
		return
	end

	for _, Instance in State.ActiveInstances do
		Instance.Cancel()
		Instance.Destroy()
	end

	EntityStates[Character] = nil
end

function ActionController.GetEntityState(Character: Model): EntityState?
	return EntityStates[Character]
end

return ActionController