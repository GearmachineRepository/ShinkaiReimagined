--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local NodeRegistry = {}

local NODE_DEFINITIONS: { [string]: Types.NodeDefinition } = {
	Wait = {
		BlockType = "Wait",
		DisplayName = "Wait",
		Description = "Pauses execution for a specified duration before continuing to the next node.",
		Color = Theme.Colors.NodeWait,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 10, Tooltip = "Time in seconds to wait before continuing." },
		},
	},

	Animation = {
		BlockType = "Animation",
		DisplayName = "Animation",
		Description = "Plays an animation on the character. Can be looped or played once.",
		Color = Theme.Colors.NodeAnimation,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "AnimationId", Label = "Animation ID", Type = "AssetId", Default = "", Tooltip = "The Roblox asset ID for the animation (e.g. rbxassetid://123456)." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 5, Tooltip = "Playback speed multiplier. 1 = normal speed." },
			{ Key = "Loop", Label = "Loop", Type = "Boolean", Default = false, Tooltip = "If enabled, animation repeats until manually stopped." },
		},
	},

	Sound = {
		BlockType = "Sound",
		DisplayName = "Sound",
		Description = "Plays a sound effect at the specified volume and pitch.",
		Color = Theme.Colors.NodeSound,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SoundId", Label = "Sound ID", Type = "AssetId", Default = "", Tooltip = "The Roblox asset ID for the sound." },
			{ Key = "Volume", Label = "Volume", Type = "Number", Default = 1, Min = 0, Max = 2, Tooltip = "Volume level. 1 = 100% volume." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Playback speed/pitch. Higher = faster and higher pitched." },
		},
	},

	Velocity = {
		BlockType = "Velocity",
		DisplayName = "Velocity",
		Description = "Applies a velocity impulse to move the character in a direction.",
		Color = Theme.Colors.NodeVelocity,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "X", Label = "X", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Horizontal velocity (left/right relative to facing)." },
			{ Key = "Y", Label = "Y", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Vertical velocity (up/down)." },
			{ Key = "Z", Label = "Z", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Forward/backward velocity relative to facing." },
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 2, Tooltip = "How long the velocity is applied." },
			{ Key = "Fade", Label = "Fade", Type = "Boolean", Default = true, Tooltip = "If enabled, velocity smoothly decreases over time." },
			{ Key = "Track", Label = "Track Target", Type = "Boolean", Default = false, Tooltip = "If enabled, velocity tracks toward the last hit target." },
		},
	},

	Hitbox = {
		BlockType = "Hitbox",
		DisplayName = "Hitbox",
		Description = "Creates a damage hitbox that detects and damages enemies within range.",
		Color = Theme.Colors.NodeHitbox,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Signal" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "X", Label = "Offset X", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Horizontal offset from character center." },
			{ Key = "Y", Label = "Offset Y", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Vertical offset from character center." },
			{ Key = "Z", Label = "Offset Z", Type = "Number", Default = 4, Min = -20, Max = 20, Tooltip = "Forward offset from character center." },
			{ Key = "SizeX", Label = "Size X", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Width of the hitbox." },
			{ Key = "SizeY", Label = "Size Y", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Height of the hitbox." },
			{ Key = "SizeZ", Label = "Size Z", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Depth of the hitbox." },
			{ Key = "Damage", Label = "Damage", Type = "Number", Default = 10, Min = 0, Max = 50, Tooltip = "Amount of damage dealt on hit." },
			{ Key = "Stun", Label = "Stun", Type = "Number", Default = 0.2, Min = 0, Max = 3, Tooltip = "Duration the target is stunned after being hit." },
			{ Key = "Blockable", Label = "Blockable", Type = "Boolean", Default = true, Tooltip = "If enabled, this attack can be blocked." },
		},
	},

	HitCancel = {
		BlockType = "HitCancel",
		DisplayName = "Hit Cancel",
		Description = "Allows canceling into another branch based on hit or miss within a time window.",
		Color = Theme.Colors.NodeHitCancel,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Flow" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Window", Type = "Number", Default = 0.5, Min = 0, Max = 5, Tooltip = "Time window in seconds to check for hit/miss." },
			{ Key = "Flip", Label = "Check Miss", Type = "Boolean", Default = false, Tooltip = "If enabled, triggers on miss instead of hit." },
			{ Key = "Branch", Label = "Branch", Type = "BranchDropdown", Default = "", Tooltip = "The branch to execute when condition is met." },
			{ Key = "Endlag", Label = "Endlag", Type = "Number", Default = 0, Min = 0, Max = 2, Tooltip = "Recovery time after the cancel window." },
		},
	},

	Branch = {
		BlockType = "Branch",
		DisplayName = "Branch",
		Description = "Jumps execution to another branch in the skill timeline.",
		Color = Theme.Colors.NodeBranch,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
		},
		Properties = {
			{ Key = "BranchName", Label = "Target Branch", Type = "BranchDropdown", Default = "", Tooltip = "The branch to jump to." },
		},
	},

	Skill = {
		BlockType = "Skill",
		DisplayName = "Sub-Skill",
		Description = "Executes another skill as part of this skill's timeline.",
		Color = Theme.Colors.NodeSkill,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "SkillId", Label = "Skill ID", Type = "String", Default = "", Tooltip = "The ID of the skill to execute." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Speed multiplier for the sub-skill." },
			{ Key = "CancelLast", Label = "Cancel Last", Type = "Boolean", Default = false, Tooltip = "If enabled, cancels any previously running skill." },
		},
	},

	Signal = {
		BlockType = "Signal",
		DisplayName = "Signal",
		Description = "Emits or clears a signal that can be used by logic gates.",
		Color = Theme.Colors.NodeSignal,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SignalId", Label = "Signal ID", Type = "String", Default = "", Tooltip = "Unique identifier for this signal." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the signal stays active. 0 = instant." },
			{ Key = "Clear", Label = "Clear Signal", Type = "Boolean", Default = false, Tooltip = "If enabled, clears the signal instead of emitting it." },
		},
	},

	AndGate = {
		BlockType = "AndGate",
		DisplayName = "AND Gate",
		Description = "Outputs a signal when a threshold number of input signals are active simultaneously.",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "", Tooltip = "Comma-separated list of signal IDs to monitor." },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 2, Min = 1, Max = 8, Tooltip = "Number of signals that must be active to pass." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit when threshold is met." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the output signal stays active." },
		},
	},

	OrGate = {
		BlockType = "OrGate",
		DisplayName = "OR Gate",
		Description = "Outputs a signal when any of the input signals are active.",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "", Tooltip = "Comma-separated list of signal IDs to monitor." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit when any input is active." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the output signal stays active." },
		},
	},

	NotGate = {
		BlockType = "NotGate",
		DisplayName = "NOT Gate",
		Description = "Outputs a signal when the input signal is NOT active.",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Input Signal", Type = "String", Default = "", Tooltip = "The signal ID to invert." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit when input is inactive." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the output signal stays active." },
		},
	},

	Timer = {
		BlockType = "Timer",
		DisplayName = "Timer",
		Description = "Waits for a trigger signal, then emits an output signal after a delay.",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnExpired", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Trigger Signal", Type = "String", Default = "", Tooltip = "Signal that starts the timer." },
			{ Key = "Time", Label = "Delay", Type = "Number", Default = 1, Min = 0.1, Max = 10, Tooltip = "Delay in seconds before output fires." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit when timer expires." },
			{ Key = "OutputDuration", Label = "Output Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the output signal stays active." },
		},
	},

	Counter = {
		BlockType = "Counter",
		DisplayName = "Counter",
		Description = "Counts input signals and emits output when a threshold is reached.",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnThreshold", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Count Signal", Type = "String", Default = "", Tooltip = "Signal to count occurrences of." },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 3, Min = 1, Max = 100, Tooltip = "Number of signals needed to trigger output." },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "", Tooltip = "Signal to emit when threshold is reached." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long the output signal stays active." },
			{ Key = "ResetOnThreshold", Label = "Reset On Trigger", Type = "Boolean", Default = true, Tooltip = "If enabled, counter resets to 0 after triggering." },
		},
	},

	AddHealth = {
		BlockType = "AddHealth",
		DisplayName = "Add Health",
		Description = "Adds or removes health from the character. Use negative values for damage.",
		Color = Theme.Colors.NodeHealth,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Amount", Label = "Amount", Type = "Number", Default = 5, Min = -50, Max = 50, Tooltip = "Health to add. Negative values deal damage." },
		},
	},

	BranchStart = {
		BlockType = "BranchStart",
		DisplayName = "Branch Start",
		Description = "Entry point for this branch. Connect this to the first node in your timeline.",
		Color = Theme.Colors.NodeBranch,
		Ports = {
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {},
	},
}

function NodeRegistry.Get(BlockType: string): Types.NodeDefinition?
	return NODE_DEFINITIONS[BlockType]
end

function NodeRegistry.GetAll(): { [string]: Types.NodeDefinition }
	return NODE_DEFINITIONS
end

function NodeRegistry.GetBlockTypes(): { string }
	local BlockTypes: { string } = {}
	for BlockType in NODE_DEFINITIONS do
		table.insert(BlockTypes, BlockType)
	end
	table.sort(BlockTypes)
	return BlockTypes
end

function NodeRegistry.GetInputPorts(BlockType: string): { Types.PortDefinition }
	local Definition = NODE_DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local InputPorts: { Types.PortDefinition } = {}
	for _, Port in Definition.Ports do
		if Port.Direction == "Input" then
			table.insert(InputPorts, Port)
		end
	end
	return InputPorts
end

function NodeRegistry.GetOutputPorts(BlockType: string): { Types.PortDefinition }
	local Definition = NODE_DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local OutputPorts: { Types.PortDefinition } = {}
	for _, Port in Definition.Ports do
		if Port.Direction == "Output" then
			table.insert(OutputPorts, Port)
		end
	end
	return OutputPorts
end

return NodeRegistry