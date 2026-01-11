--!strict

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)

local NodeRegistry = {}

local NODE_DEFINITIONS: { [string]: Types.NodeDefinition } = {
	Wait = {
		BlockType = "Wait",
		DisplayName = "Wait",
		Color = Theme.Colors.NodeWait,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 10 },
		},
	},

	Animation = {
		BlockType = "Animation",
		DisplayName = "Animation",
		Color = Theme.Colors.NodeAnimation,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "AnimationId", Label = "Animation ID", Type = "AssetId", Default = "" },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 5 },
			{ Key = "Loop", Label = "Loop", Type = "Boolean", Default = false },
		},
	},

	Sound = {
		BlockType = "Sound",
		DisplayName = "Sound",
		Color = Theme.Colors.NodeSound,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SoundId", Label = "Sound ID", Type = "AssetId", Default = "" },
			{ Key = "Volume", Label = "Volume", Type = "Number", Default = 1, Min = 0, Max = 2 },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3 },
		},
	},

	Velocity = {
		BlockType = "Velocity",
		DisplayName = "Velocity",
		Color = Theme.Colors.NodeVelocity,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "X", Label = "X", Type = "Number", Default = 0, Min = -100, Max = 100 },
			{ Key = "Y", Label = "Y", Type = "Number", Default = 0, Min = -100, Max = 100 },
			{ Key = "Z", Label = "Z", Type = "Number", Default = 0, Min = -100, Max = 100 },
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 2 },
			{ Key = "Fade", Label = "Fade", Type = "Boolean", Default = true },
			{ Key = "Track", Label = "Track Target", Type = "Boolean", Default = false },
		},
	},

	Hitbox = {
		BlockType = "Hitbox",
		DisplayName = "Hitbox",
		Color = Theme.Colors.NodeHitbox,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Signal" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "X", Label = "Offset X", Type = "Number", Default = 0, Min = -20, Max = 20 },
			{ Key = "Y", Label = "Offset Y", Type = "Number", Default = 0, Min = -20, Max = 20 },
			{ Key = "Z", Label = "Offset Z", Type = "Number", Default = 4, Min = -20, Max = 20 },
			{ Key = "SizeX", Label = "Size X", Type = "Number", Default = 6, Min = 1, Max = 20 },
			{ Key = "SizeY", Label = "Size Y", Type = "Number", Default = 6, Min = 1, Max = 20 },
			{ Key = "SizeZ", Label = "Size Z", Type = "Number", Default = 6, Min = 1, Max = 20 },
			{ Key = "Damage", Label = "Damage", Type = "Number", Default = 10, Min = 0, Max = 50 },
			{ Key = "Stun", Label = "Stun", Type = "Number", Default = 0.2, Min = 0, Max = 3 },
			{ Key = "Blockable", Label = "Blockable", Type = "Boolean", Default = true },
		},
	},

	HitCancel = {
		BlockType = "HitCancel",
		DisplayName = "Hit Cancel",
		Color = Theme.Colors.NodeHitCancel,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Flow" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Window", Type = "Number", Default = 0.5, Min = 0, Max = 5 },
			{ Key = "Flip", Label = "Check Miss", Type = "Boolean", Default = false },
			{ Key = "Branch", Label = "Branch", Type = "String", Default = "" },
			{ Key = "Endlag", Label = "Endlag", Type = "Number", Default = 0, Min = 0, Max = 2 },
		},
	},

	Branch = {
		BlockType = "Branch",
		DisplayName = "Branch",
		Color = Theme.Colors.NodeBranch,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
		},
		Properties = {
			{ Key = "BranchName", Label = "Target Branch", Type = "String", Default = "" },
		},
	},

	Skill = {
		BlockType = "Skill",
		DisplayName = "Sub-Skill",
		Color = Theme.Colors.NodeSkill,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "SkillId", Label = "Skill ID", Type = "String", Default = "" },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3 },
			{ Key = "CancelLast", Label = "Cancel Last", Type = "Boolean", Default = false },
		},
	},

	Signal = {
		BlockType = "Signal",
		DisplayName = "Signal",
		Color = Theme.Colors.NodeSignal,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "SignalId", Label = "Signal ID", Type = "String", Default = "" },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
			{ Key = "Clear", Label = "Clear Signal", Type = "Boolean", Default = false },
		},
	},

	AndGate = {
		BlockType = "AndGate",
		DisplayName = "AND Gate",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "" },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 2, Min = 1, Max = 8 },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "" },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
		},
	},

	OrGate = {
		BlockType = "OrGate",
		DisplayName = "OR Gate",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Inputs", Label = "Input Signals", Type = "String", Default = "" },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "" },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
		},
	},

	NotGate = {
		BlockType = "NotGate",
		DisplayName = "NOT Gate",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnPass", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Input Signal", Type = "String", Default = "" },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "" },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
		},
	},

	Timer = {
		BlockType = "Timer",
		DisplayName = "Timer",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnExpired", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Trigger Signal", Type = "String", Default = "" },
			{ Key = "Time", Label = "Delay", Type = "Number", Default = 1, Min = 0.1, Max = 10 },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "" },
			{ Key = "OutputDuration", Label = "Output Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
		},
	},

	Counter = {
		BlockType = "Counter",
		DisplayName = "Counter",
		Color = Theme.Colors.NodeGate,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnThreshold", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Input", Label = "Count Signal", Type = "String", Default = "" },
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 3, Min = 1, Max = 100 },
			{ Key = "Output", Label = "Output Signal", Type = "String", Default = "" },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10 },
			{ Key = "ResetOnThreshold", Label = "Reset On Trigger", Type = "Boolean", Default = true },
		},
	},

	AddHealth = {
		BlockType = "AddHealth",
		DisplayName = "Add Health",
		Color = Theme.Colors.NodeHealth,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Amount", Label = "Amount", Type = "Number", Default = 5, Min = -50, Max = 50 },
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