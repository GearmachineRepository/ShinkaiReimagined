--!strict

local BlockDefinitions = {}

export type PortDirection = "Input" | "Output"
export type PortType = "Flow" | "Signal"

export type PortDefinition = {
	Name: string,
	Direction: PortDirection,
	PortType: PortType,
}

export type PropertyType = "String" | "Number" | "Boolean" | "Dropdown" | "AssetId" | "BranchDropdown"

export type PropertyDefinition = {
	Key: string,
	Label: string,
	Type: PropertyType,
	Default: any,
	Min: number?,
	Max: number?,
	Options: { string }?,
	Tooltip: string?,
}

export type BlockDefinition = {
	BlockType: string,
	Category: string,
	DisplayName: string,
	Description: string,
	Color: Color3,
	Ports: { PortDefinition },
	Properties: { PropertyDefinition },
}

local COLORS = {
	Flow = Color3.fromRGB(100, 140, 180),
	Combat = Color3.fromRGB(200, 80, 80),
	Effects = Color3.fromRGB(140, 100, 180),
	Logic = Color3.fromRGB(180, 160, 80),
	Advanced = Color3.fromRGB(80, 160, 140),
	Utility = Color3.fromRGB(90, 90, 95),
}

local DEFINITIONS: { [string]: BlockDefinition } = {
	Wait = {
		BlockType = "Wait",
		Category = "Flow",
		DisplayName = "Wait",
		Description = "Pauses execution for a specified duration before continuing.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 10, Tooltip = "Time in seconds to wait." },
		},
	},

	Branch = {
		BlockType = "Branch",
		Category = "Flow",
		DisplayName = "Branch",
		Description = "Jumps execution to a different branch.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Target", Label = "Target Branch", Type = "BranchDropdown", Default = "", Tooltip = "The branch to jump to." },
		},
	},

	Hitbox = {
		BlockType = "Hitbox",
		Category = "Combat",
		DisplayName = "Hitbox",
		Description = "Creates a damage hitbox that detects and damages enemies.",
		Color = COLORS.Combat,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Signal" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "X", Label = "Offset X", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Horizontal offset." },
			{ Key = "Y", Label = "Offset Y", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Vertical offset." },
			{ Key = "Z", Label = "Offset Z", Type = "Number", Default = 4, Min = -20, Max = 20, Tooltip = "Forward offset." },
			{ Key = "SizeX", Label = "Size X", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Width." },
			{ Key = "SizeY", Label = "Size Y", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Height." },
			{ Key = "SizeZ", Label = "Size Z", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Depth." },
			{ Key = "Damage", Label = "Damage", Type = "Number", Default = 10, Min = 0, Max = 50, Tooltip = "Damage dealt." },
			{ Key = "Stun", Label = "Stun", Type = "Number", Default = 0.2, Min = 0, Max = 3, Tooltip = "Stun duration." },
			{ Key = "Blockable", Label = "Blockable", Type = "Boolean", Default = true, Tooltip = "Can be blocked." },
		},
	},

	HitCancel = {
		BlockType = "HitCancel",
		Category = "Combat",
		DisplayName = "Hit Cancel",
		Description = "Branches based on whether a hit occurred within a time window.",
		Color = COLORS.Combat,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Window", Type = "Number", Default = 0.3, Min = 0, Max = 2, Tooltip = "Time window to check for hits." },
			{ Key = "Flip", Label = "On Miss", Type = "Boolean", Default = false, Tooltip = "Trigger on miss instead of hit." },
			{ Key = "Branch", Label = "Branch", Type = "BranchDropdown", Default = "", Tooltip = "Branch to jump to." },
			{ Key = "Endlag", Label = "Endlag", Type = "Number", Default = 0, Min = 0, Max = 1, Tooltip = "Delay before branching." },
		},
	},

	AddHealth = {
		BlockType = "AddHealth",
		Category = "Combat",
		DisplayName = "Add Health",
		Description = "Adds or removes health. Use negative values for damage.",
		Color = COLORS.Combat,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Amount", Label = "Amount", Type = "Number", Default = 5, Min = -50, Max = 50, Tooltip = "Health to add." },
		},
	},

	Animation = {
		BlockType = "Animation",
		Category = "Effects",
		DisplayName = "Animation",
		Description = "Plays an animation on the character.",
		Color = COLORS.Effects,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "AnimationId", Label = "Animation ID", Type = "AssetId", Default = "", Tooltip = "Roblox animation asset ID." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 5, Tooltip = "Playback speed." },
			{ Key = "Loop", Label = "Loop", Type = "Boolean", Default = false, Tooltip = "Repeat until stopped." },
		},
	},

	Sound = {
		BlockType = "Sound",
		Category = "Effects",
		DisplayName = "Sound",
		Description = "Plays a sound effect.",
		Color = COLORS.Effects,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SoundId", Label = "Sound ID", Type = "AssetId", Default = "", Tooltip = "Roblox sound asset ID." },
			{ Key = "Volume", Label = "Volume", Type = "Number", Default = 1, Min = 0, Max = 2, Tooltip = "Volume level." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Playback speed." },
		},
	},

	Velocity = {
		BlockType = "Velocity",
		Category = "Effects",
		DisplayName = "Velocity",
		Description = "Applies a velocity impulse to move the character.",
		Color = COLORS.Effects,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "X", Label = "X", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Horizontal velocity." },
			{ Key = "Y", Label = "Y", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Vertical velocity." },
			{ Key = "Z", Label = "Z", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Forward velocity." },
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 2, Tooltip = "How long velocity applies." },
			{ Key = "Fade", Label = "Fade", Type = "Boolean", Default = true, Tooltip = "Smoothly decrease over time." },
			{ Key = "Track", Label = "Track Target", Type = "Boolean", Default = false, Tooltip = "Track toward last hit target." },
		},
	},

	Signal = {
		BlockType = "Signal",
		Category = "Logic",
		DisplayName = "Signal",
		Description = "Emits or clears a signal for logic gates.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SignalId", Label = "Signal ID", Type = "String", Default = "", Tooltip = "Unique signal identifier." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long signal stays active." },
			{ Key = "Clear", Label = "Clear", Type = "Boolean", Default = false, Tooltip = "Clear instead of emit." },
		},
	},

	AndGate = {
		BlockType = "AndGate",
		Category = "Logic",
		DisplayName = "AND Gate",
		Description = "Outputs when threshold number of input signals are active.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "", Tooltip = "Comma-separated signal IDs." },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 2, Min = 1, Max = 8, Tooltip = "Signals needed to pass." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit on pass." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "Output signal duration." },
		},
	},

	OrGate = {
		BlockType = "OrGate",
		Category = "Logic",
		DisplayName = "OR Gate",
		Description = "Outputs when any input signal is active.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "", Tooltip = "Comma-separated signal IDs." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit on pass." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "Output signal duration." },
		},
	},

	NotGate = {
		BlockType = "NotGate",
		Category = "Logic",
		DisplayName = "NOT Gate",
		Description = "Outputs when input signal is NOT active.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Input Signal", Type = "String", Default = "", Tooltip = "Signal to invert." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "Output signal duration." },
		},
	},

	Timer = {
		BlockType = "Timer",
		Category = "Logic",
		DisplayName = "Timer",
		Description = "Emits output signal after a delay when triggered.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnExpired", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Trigger Signal", Type = "String", Default = "", Tooltip = "Signal that starts timer." },
			{ Key = "Time", Label = "Delay", Type = "Number", Default = 1, Min = 0.1, Max = 10, Tooltip = "Seconds before output." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit." },
			{ Key = "OutputDuration", Label = "Output Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "Output signal duration." },
		},
	},

	Counter = {
		BlockType = "Counter",
		Category = "Logic",
		DisplayName = "Counter",
		Description = "Counts signal occurrences and outputs at threshold.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnThreshold", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Count Signal", Type = "String", Default = "", Tooltip = "Signal to count." },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 3, Min = 1, Max = 100, Tooltip = "Count to trigger." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "Output signal duration." },
			{ Key = "ResetOnThreshold", Label = "Reset On Trigger", Type = "Boolean", Default = true, Tooltip = "Reset counter after triggering." },
		},
	},

	Action = {
		BlockType = "Action",
		Category = "Advanced",
		DisplayName = "Action",
		Description = "Executes another action definition as a sub-action.",
		Color = COLORS.Advanced,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "ActionId", Label = "Action ID", Type = "String", Default = "", Tooltip = "ID of action to execute." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Speed multiplier." },
			{ Key = "CancelLast", Label = "Cancel Last", Type = "Boolean", Default = false, Tooltip = "Cancel previous action." },
		},
	},

	BranchStart = {
		BlockType = "BranchStart",
		Category = "Flow",
		DisplayName = "Branch Start",
		Description = "Entry point for this branch. Connect this to the first node in your timeline.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {},
	},
}

local CATEGORIES = {
    { Name = "Utility", Types = { "Comment" } },
    { Name = "Flow", Types = { "BranchStart", "Wait", "Branch" } },
    { Name = "Combat", Types = { "Hitbox", "HitCancel", "AddHealth" } },
    { Name = "Effects", Types = { "Animation", "Sound", "Velocity" } },
    { Name = "Logic", Types = { "Signal", "AndGate", "OrGate", "NotGate", "Timer", "Counter" } },
    { Name = "Advanced", Types = { "Action" } },
}

function BlockDefinitions.Get(BlockType: string): BlockDefinition?
	return DEFINITIONS[BlockType]
end

function BlockDefinitions.GetAll(): { [string]: BlockDefinition }
	return DEFINITIONS
end

function BlockDefinitions.GetCategories(): { { Name: string, Types: { string } } }
	return CATEGORIES
end

function BlockDefinitions.GetBlockTypes(): { string }
	local Types: { string } = {}
	for BlockType in DEFINITIONS do
		table.insert(Types, BlockType)
	end
	table.sort(Types)
	return Types
end

function BlockDefinitions.GetInputPorts(BlockType: string): { PortDefinition }
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local InputPorts: { PortDefinition } = {}
	for _, Port in Definition.Ports do
		if Port.Direction == "Input" then
			table.insert(InputPorts, Port)
		end
	end
	return InputPorts
end

function BlockDefinitions.GetOutputPorts(BlockType: string): { PortDefinition }
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local OutputPorts: { PortDefinition } = {}
	for _, Port in Definition.Ports do
		if Port.Direction == "Output" then
			table.insert(OutputPorts, Port)
		end
	end
	return OutputPorts
end

function BlockDefinitions.GetSignalOutputs(BlockType: string): { string }
	local OutputPorts = BlockDefinitions.GetOutputPorts(BlockType)
	local SignalOutputs: { string } = {}

	for _, Port in OutputPorts do
		if Port.PortType == "Signal" then
			table.insert(SignalOutputs, Port.Name)
		end
	end

	return SignalOutputs
end

function BlockDefinitions.GetDefaultProperties(BlockType: string): { [string]: any }
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local Defaults: { [string]: any } = {}
	for _, PropertyDef in Definition.Properties do
		Defaults[PropertyDef.Key] = PropertyDef.Default
	end
	return Defaults
end

function BlockDefinitions.GetColors(): { [string]: Color3 }
	return COLORS
end

return BlockDefinitions
