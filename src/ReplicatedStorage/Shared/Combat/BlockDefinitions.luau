--!strict

local BlockDefinitions = {}

export type PortDirection = "Input" | "Output"
export type PortType = "Flow" | "Signal" | "Value"
export type ValueType = "Number" | "Boolean" | "String" | "Vector3" | "Entity" | "EntityList" | "Any"

export type PortDefinition = {
	Name: string,
	Direction: PortDirection,
	PortType: PortType,
	ValueType: ValueType?,
	PropertyKey: string?,
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
	Wireable: boolean?,
}

export type BlockDefinition = {
	BlockType: string,
	Category: string,
	DisplayName: string,
	Description: string,
	Color: Color3,
	Ports: { PortDefinition },
	Properties: { PropertyDefinition },
	Pure: boolean?,
}

local COLORS = {
	Flow = Color3.fromRGB(83, 108, 133),
	Combat = Color3.fromRGB(167, 83, 83),
	Effects = Color3.fromRGB(116, 91, 141),
	Logic = Color3.fromRGB(160, 146, 91),
	Advanced = Color3.fromRGB(78, 138, 123),
	Utility = Color3.fromRGB(90, 90, 95),
	Condition = Color3.fromRGB(89, 134, 89),
	Value = Color3.fromRGB(106, 135, 89),
	Boolean = Color3.fromRGB(180, 100, 100),
	Entity = Color3.fromRGB(100, 160, 200),
}

local DEFINITIONS: { [string]: BlockDefinition } = {
	BranchStart = {
		BlockType = "BranchStart",
		Category = "Flow",
		DisplayName = "Branch Start",
		Description = "Entry point for this branch. Execution begins here.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {},
	},

	Wait = {
		BlockType = "Wait",
		Category = "Flow",
		DisplayName = "Wait",
		Description = "Pauses execution for a specified duration.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Time", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Time" },
		},
		Properties = {
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 10, Tooltip = "Time in seconds.", Wireable = true },
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
			{ Key = "BranchName", Label = "Target Branch", Type = "BranchDropdown", Default = "", Tooltip = "Branch to jump to." },
		},
	},

	Gate = {
		BlockType = "Gate",
		Category = "Flow",
		DisplayName = "Gate",
		Description = "Triggers output flow when the connected signal fires.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "Signal", Direction = "Input", PortType = "Signal" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
		},
		Properties = {},
	},

	Condition = {
		BlockType = "Condition",
		Category = "Flow",
		DisplayName = "Condition",
		Description = "Branches based on a boolean condition.",
		Color = COLORS.Condition,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "True", Direction = "Output", PortType = "Flow" },
			{ Name = "False", Direction = "Output", PortType = "Flow" },
			{ Name = "Condition", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "ConditionValue" },
		},
		Properties = {
			{ Key = "ConditionValue", Label = "Condition", Type = "Boolean", Default = false, Tooltip = "Condition from wire.", Wireable = true },
		},
	},

	Cancel = {
		BlockType = "Cancel",
		Category = "Flow",
		DisplayName = "Cancel",
		Description = "Cancels the current action execution.",
		Color = COLORS.Flow,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
		},
		Properties = {},
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
			{ Name = "Targets", Direction = "Output", PortType = "Value", ValueType = "EntityList" },
			{ Name = "Damage", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Damage" },
			{ Name = "Stun", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Stun" },
		},
		Properties = {
			{ Key = "X", Label = "Offset X", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Horizontal offset." },
			{ Key = "Y", Label = "Offset Y", Type = "Number", Default = 0, Min = -20, Max = 20, Tooltip = "Vertical offset." },
			{ Key = "Z", Label = "Offset Z", Type = "Number", Default = 4, Min = -20, Max = 20, Tooltip = "Forward offset." },
			{ Key = "SizeX", Label = "Size X", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Width." },
			{ Key = "SizeY", Label = "Size Y", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Height." },
			{ Key = "SizeZ", Label = "Size Z", Type = "Number", Default = 6, Min = 1, Max = 20, Tooltip = "Depth." },
			{ Key = "Damage", Label = "Damage", Type = "Number", Default = 10, Min = 0, Max = 100, Tooltip = "Damage dealt.", Wireable = true },
			{ Key = "Stun", Label = "Stun", Type = "Number", Default = 0.2, Min = 0, Max = 5, Tooltip = "Stun duration.", Wireable = true },
			{ Key = "Blockable", Label = "Blockable", Type = "Boolean", Default = true, Tooltip = "Can be blocked." },
		},
	},

	HitWindow = {
		BlockType = "HitWindow",
		Category = "Combat",
		DisplayName = "Hit Window",
		Description = "Waits for a time window, then branches based on hit/miss.",
		Color = COLORS.Combat,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "OnHit", Direction = "Output", PortType = "Flow" },
			{ Name = "OnMiss", Direction = "Output", PortType = "Flow" },
		},
		Properties = {
			{ Key = "Time", Label = "Window", Type = "Number", Default = 0.3, Min = 0, Max = 2, Tooltip = "Time window to check for hits." },
			{ Key = "Endlag", Label = "Endlag", Type = "Number", Default = 0, Min = 0, Max = 1, Tooltip = "Delay before branching." },
		},
	},

	ModifyHealth = {
		BlockType = "ModifyHealth",
		Category = "Combat",
		DisplayName = "Modify Health",
		Description = "Adds or removes health from a target. Negative values deal damage.",
		Color = COLORS.Combat,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Target", Direction = "Input", PortType = "Value", ValueType = "Entity", PropertyKey = "TargetMode" },
			{ Name = "Amount", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Amount" },
		},
		Properties = {
			{ Key = "TargetMode", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit" }, Tooltip = "Who to modify." },
			{ Key = "Amount", Label = "Amount", Type = "Number", Default = 10, Min = -1000, Max = 1000, Tooltip = "Health to add (flat value).", Wireable = true },
		},
	},

	Animation = {
		BlockType = "Animation",
		Category = "Effects",
		DisplayName = "Animation",
		Description = "Plays an animation. Blocks until complete if not looping.",
		Color = COLORS.Effects,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
			{ Name = "Speed", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Speed" },
		},
		Properties = {
			{ Key = "AnimationId", Label = "Animation ID", Type = "AssetId", Default = "", Tooltip = "Roblox animation asset ID." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Playback speed.", Wireable = true },
			{ Key = "Loop", Label = "Loop", Type = "Boolean", Default = false, Tooltip = "Loop the animation." },
			{ Key = "Wait", Label = "Wait", Type = "Boolean", Default = true, Tooltip = "Wait for animation to finish." },
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
			{ Name = "Volume", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Volume" },
		},
		Properties = {
			{ Key = "SoundId", Label = "Sound ID", Type = "AssetId", Default = "", Tooltip = "Roblox sound asset ID." },
			{ Key = "Volume", Label = "Volume", Type = "Number", Default = 1, Min = 0, Max = 2, Tooltip = "Volume level.", Wireable = true },
			{ Key = "Pitch", Label = "Pitch", Type = "Number", Default = 1, Min = 0.5, Max = 2, Tooltip = "Pitch multiplier." },
		},
	},

	Velocity = {
		BlockType = "Velocity",
		Category = "Effects",
		DisplayName = "Velocity",
		Description = "Applies velocity to the entity.",
		Color = COLORS.Effects,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "X", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "X" },
			{ Name = "Y", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Y" },
			{ Name = "Z", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Z" },
		},
		Properties = {
			{ Key = "X", Label = "X", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Horizontal velocity.", Wireable = true },
			{ Key = "Y", Label = "Y", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Vertical velocity.", Wireable = true },
			{ Key = "Z", Label = "Z", Type = "Number", Default = 0, Min = -100, Max = 100, Tooltip = "Forward velocity.", Wireable = true },
			{ Key = "Time", Label = "Duration", Type = "Number", Default = 0.1, Min = 0, Max = 2, Tooltip = "How long velocity applies." },
			{ Key = "Fade", Label = "Fade", Type = "Boolean", Default = true, Tooltip = "Smoothly decrease over time." },
			{ Key = "Track", Label = "Track Target", Type = "Boolean", Default = false, Tooltip = "Track toward last hit target." },
		},
	},

	EmitSignal = {
		BlockType = "EmitSignal",
		Category = "Logic",
		DisplayName = "Emit Signal",
		Description = "Emits a custom signal that other nodes can listen for.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Signal", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "SignalId", Label = "Signal Name", Type = "String", Default = "", Tooltip = "Custom signal identifier." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 10, Tooltip = "How long signal stays active. 0 = instant pulse." },
		},
	},

	Timer = {
		BlockType = "Timer",
		Category = "Logic",
		DisplayName = "Timer",
		Description = "Starts a timer when triggered. Emits signal after delay.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Trigger", Direction = "Input", PortType = "Signal" },
			{ Name = "OnExpired", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Time", Label = "Delay", Type = "Number", Default = 1, Min = 0.1, Max = 10, Tooltip = "Seconds before signal fires." },
		},
	},

	Counter = {
		BlockType = "Counter",
		Category = "Logic",
		DisplayName = "Counter",
		Description = "Counts signal occurrences. Emits when threshold reached.",
		Color = COLORS.Logic,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Count", Direction = "Input", PortType = "Signal" },
			{ Name = "OnThreshold", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "Threshold", Label = "Threshold", Type = "Number", Default = 3, Min = 1, Max = 100, Tooltip = "Count to trigger." },
			{ Key = "ResetOnThreshold", Label = "Reset", Type = "Boolean", Default = true, Tooltip = "Reset counter after triggering." },
		},
	},

	Self = {
		BlockType = "Self",
		Category = "Entity",
		DisplayName = "Self",
		Description = "Returns the entity executing this action.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Entity", Direction = "Output", PortType = "Value", ValueType = "Entity" },
		},
		Properties = {},
	},

	LastHitTarget = {
		BlockType = "LastHitTarget",
		Category = "Entity",
		DisplayName = "Last Hit Target",
		Description = "Returns the most recently hit target.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Entity", Direction = "Output", PortType = "Value", ValueType = "Entity" },
			{ Name = "Valid", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {},
	},

	SelectTarget = {
		BlockType = "SelectTarget",
		Category = "Entity",
		DisplayName = "Select Target",
		Description = "Selects a single target from a list based on criteria.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Targets", Direction = "Input", PortType = "Value", ValueType = "EntityList" },
			{ Name = "Target", Direction = "Output", PortType = "Value", ValueType = "Entity" },
			{ Name = "Found", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "Criteria", Label = "Criteria", Type = "Dropdown", Default = "Nearest", Options = { "Nearest", "Farthest", "LowestHealth", "HighestHealth", "Random" }, Tooltip = "Selection criteria." },
		},
	},

	GetStat = {
		BlockType = "GetStat",
		Category = "Entity",
		DisplayName = "Get Stat",
		Description = "Gets a stat value from an entity.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Target", Direction = "Input", PortType = "Value", ValueType = "Entity" },
			{ Name = "Value", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "TargetMode", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit", "Input" }, Tooltip = "Target entity." },
			{ Key = "Stat", Label = "Stat", Type = "String", Default = "Health", Tooltip = "Stat name to get." },
		},
	},

	SetStat = {
		BlockType = "SetStat",
		Category = "Entity",
		DisplayName = "Set Stat",
		Description = "Sets a stat value on an entity.",
		Color = COLORS.Entity,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Target", Direction = "Input", PortType = "Value", ValueType = "Entity" },
			{ Name = "Value", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Value" },
		},
		Properties = {
			{ Key = "TargetMode", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit", "Input" }, Tooltip = "Target entity." },
			{ Key = "Stat", Label = "Stat", Type = "String", Default = "Health", Tooltip = "Stat name to set." },
			{ Key = "Mode", Label = "Mode", Type = "Dropdown", Default = "Set", Options = { "Set", "Add", "Multiply" }, Tooltip = "How to apply the value." },
			{ Key = "Value", Label = "Value", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Value to apply.", Wireable = true },
		},
	},

	GetState = {
		BlockType = "GetState",
		Category = "Entity",
		DisplayName = "Get State",
		Description = "Gets whether a state is active on an entity.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Target", Direction = "Input", PortType = "Value", ValueType = "Entity" },
			{ Name = "Active", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "TargetMode", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit", "Input" }, Tooltip = "Target entity." },
			{ Key = "State", Label = "State", Type = "String", Default = "Blocking", Tooltip = "State name to check." },
		},
	},

	SetState = {
		BlockType = "SetState",
		Category = "Entity",
		DisplayName = "Set State",
		Description = "Sets a state on an entity.",
		Color = COLORS.Entity,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "Target", Direction = "Input", PortType = "Value", ValueType = "Entity" },
		},
		Properties = {
			{ Key = "TargetMode", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit", "Input" }, Tooltip = "Target entity." },
			{ Key = "State", Label = "State", Type = "String", Default = "Blocking", Tooltip = "State name to set." },
			{ Key = "Active", Label = "Active", Type = "Boolean", Default = true, Tooltip = "State value." },
			{ Key = "Duration", Label = "Duration", Type = "Number", Default = 0, Min = 0, Max = 60, Tooltip = "Auto-clear after seconds. 0 = permanent." },
		},
	},

	Constant = {
		BlockType = "Constant",
		Category = "Value",
		DisplayName = "Constant",
		Description = "Outputs a constant value.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "Value", Direction = "Output", PortType = "Value", ValueType = "Any" },
		},
		Properties = {
			{ Key = "Type", Label = "Type", Type = "Dropdown", Default = "Number", Options = { "Number", "Boolean", "String" }, Tooltip = "Value type." },
			{ Key = "NumberValue", Label = "Number", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Number value." },
			{ Key = "BooleanValue", Label = "Boolean", Type = "Boolean", Default = false, Tooltip = "Boolean value." },
			{ Key = "StringValue", Label = "String", Type = "String", Default = "", Tooltip = "String value." },
		},
	},

	GetHealth = {
		BlockType = "GetHealth",
		Category = "Value",
		DisplayName = "Get Health",
		Description = "Gets the current or max health of the entity.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "Current", Direction = "Output", PortType = "Value", ValueType = "Number" },
			{ Name = "Max", Direction = "Output", PortType = "Value", ValueType = "Number" },
			{ Name = "Percent", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "Target", Label = "Target", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit" }, Tooltip = "Whose health to get." },
		},
	},

	GetDistance = {
		BlockType = "GetDistance",
		Category = "Entity",
		DisplayName = "Get Distance",
		Description = "Gets the distance between two entities.",
		Color = COLORS.Entity,
		Pure = true,
		Ports = {
			{ Name = "Distance", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "From", Label = "From", Type = "Dropdown", Default = "Self", Options = { "Self", "LastHit" }, Tooltip = "First entity." },
			{ Key = "To", Label = "To", Type = "Dropdown", Default = "LastHit", Options = { "Self", "LastHit" }, Tooltip = "Second entity." },
		},
	},

	Compare = {
		BlockType = "Compare",
		Category = "Value",
		DisplayName = "Compare",
		Description = "Compares two numbers and outputs a boolean.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "A", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "A" },
			{ Name = "B", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "B" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "A", Label = "A", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "First value.", Wireable = true },
			{ Key = "Operator", Label = "Operator", Type = "Dropdown", Default = ">", Options = { ">", "<", ">=", "<=", "==", "!=" }, Tooltip = "Comparison operator." },
			{ Key = "B", Label = "B", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Second value.", Wireable = true },
		},
	},

	Math = {
		BlockType = "Math",
		Category = "Value",
		DisplayName = "Math",
		Description = "Performs a math operation on two numbers.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "A", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "A" },
			{ Name = "B", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "B" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "A", Label = "A", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "First operand.", Wireable = true },
			{ Key = "Operator", Label = "Operator", Type = "Dropdown", Default = "+", Options = { "+", "-", "*", "/", "%", "^", "min", "max" }, Tooltip = "Math operator." },
			{ Key = "B", Label = "B", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Second operand.", Wireable = true },
		},
	},

	Random = {
		BlockType = "Random",
		Category = "Value",
		DisplayName = "Random",
		Description = "Generates a random number between min and max.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "Min", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Min" },
			{ Name = "Max", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Max" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "Min", Label = "Min", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Minimum value.", Wireable = true },
			{ Key = "Max", Label = "Max", Type = "Number", Default = 1, Min = -9999, Max = 9999, Tooltip = "Maximum value.", Wireable = true },
			{ Key = "Integer", Label = "Integer", Type = "Boolean", Default = false, Tooltip = "Round to integer." },
		},
	},

	Clamp = {
		BlockType = "Clamp",
		Category = "Value",
		DisplayName = "Clamp",
		Description = "Clamps a value between min and max.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "Value", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Value" },
			{ Name = "Min", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Min" },
			{ Name = "Max", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Max" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "Value", Label = "Value", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Value to clamp.", Wireable = true },
			{ Key = "Min", Label = "Min", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Minimum.", Wireable = true },
			{ Key = "Max", Label = "Max", Type = "Number", Default = 1, Min = -9999, Max = 9999, Tooltip = "Maximum.", Wireable = true },
		},
	},

	Lerp = {
		BlockType = "Lerp",
		Category = "Value",
		DisplayName = "Lerp",
		Description = "Linearly interpolates between two values.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "A", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "A" },
			{ Name = "B", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "B" },
			{ Name = "Alpha", Direction = "Input", PortType = "Value", ValueType = "Number", PropertyKey = "Alpha" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Number" },
		},
		Properties = {
			{ Key = "A", Label = "A", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Start value.", Wireable = true },
			{ Key = "B", Label = "B", Type = "Number", Default = 1, Min = -9999, Max = 9999, Tooltip = "End value.", Wireable = true },
			{ Key = "Alpha", Label = "Alpha", Type = "Number", Default = 0.5, Min = 0, Max = 1, Tooltip = "Interpolation factor.", Wireable = true },
		},
	},

	Select = {
		BlockType = "Select",
		Category = "Value",
		DisplayName = "Select",
		Description = "Selects between two values based on a condition.",
		Color = COLORS.Value,
		Pure = true,
		Ports = {
			{ Name = "Condition", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "Condition" },
			{ Name = "True", Direction = "Input", PortType = "Value", ValueType = "Any", PropertyKey = "TrueValue" },
			{ Name = "False", Direction = "Input", PortType = "Value", ValueType = "Any", PropertyKey = "FalseValue" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Any" },
		},
		Properties = {
			{ Key = "Condition", Label = "Condition", Type = "Boolean", Default = true, Tooltip = "Selection condition.", Wireable = true },
			{ Key = "TrueValue", Label = "True Value", Type = "Number", Default = 1, Min = -9999, Max = 9999, Tooltip = "Value if true.", Wireable = true },
			{ Key = "FalseValue", Label = "False Value", Type = "Number", Default = 0, Min = -9999, Max = 9999, Tooltip = "Value if false.", Wireable = true },
		},
	},

	And = {
		BlockType = "And",
		Category = "Boolean",
		DisplayName = "AND",
		Description = "Returns true if both inputs are true.",
		Color = COLORS.Boolean,
		Pure = true,
		Ports = {
			{ Name = "A", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "A" },
			{ Name = "B", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "B" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "A", Label = "A", Type = "Boolean", Default = false, Tooltip = "First boolean.", Wireable = true },
			{ Key = "B", Label = "B", Type = "Boolean", Default = false, Tooltip = "Second boolean.", Wireable = true },
		},
	},

	Or = {
		BlockType = "Or",
		Category = "Boolean",
		DisplayName = "OR",
		Description = "Returns true if either input is true.",
		Color = COLORS.Boolean,
		Pure = true,
		Ports = {
			{ Name = "A", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "A" },
			{ Name = "B", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "B" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "A", Label = "A", Type = "Boolean", Default = false, Tooltip = "First boolean.", Wireable = true },
			{ Key = "B", Label = "B", Type = "Boolean", Default = false, Tooltip = "Second boolean.", Wireable = true },
		},
	},

	Not = {
		BlockType = "Not",
		Category = "Boolean",
		DisplayName = "NOT",
		Description = "Returns the opposite of the input.",
		Color = COLORS.Boolean,
		Pure = true,
		Ports = {
			{ Name = "Value", Direction = "Input", PortType = "Value", ValueType = "Boolean", PropertyKey = "Value" },
			{ Name = "Result", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "Value", Label = "Value", Type = "Boolean", Default = false, Tooltip = "Boolean to invert.", Wireable = true },
		},
	},

	SignalActive = {
		BlockType = "SignalActive",
		Category = "Boolean",
		DisplayName = "Signal Active",
		Description = "Returns true if the signal is currently active.",
		Color = COLORS.Boolean,
		Pure = true,
		Ports = {
			{ Name = "Signal", Direction = "Input", PortType = "Signal" },
			{ Name = "Active", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {},
	},

	GetTag = {
		BlockType = "GetTag",
		Category = "Boolean",
		DisplayName = "Get Tag",
		Description = "Gets the value of a combat tag.",
		Color = COLORS.Boolean,
		Pure = true,
		Ports = {
			{ Name = "Value", Direction = "Output", PortType = "Value", ValueType = "Boolean" },
		},
		Properties = {
			{ Key = "Tag", Label = "Tag", Type = "String", Default = "", Tooltip = "Tag name to check." },
		},
	},

	SubAction = {
		BlockType = "SubAction",
		Category = "Advanced",
		DisplayName = "Sub-Action",
		Description = "Executes another action. Blocks until complete.",
		Color = COLORS.Advanced,
		Ports = {
			{ Name = "In", Direction = "Input", PortType = "Flow" },
			{ Name = "Out", Direction = "Output", PortType = "Flow" },
			{ Name = "OnComplete", Direction = "Output", PortType = "Signal" },
		},
		Properties = {
			{ Key = "ActionId", Label = "Action ID", Type = "String", Default = "", Tooltip = "ID of action to execute." },
			{ Key = "Speed", Label = "Speed", Type = "Number", Default = 1, Min = 0.1, Max = 3, Tooltip = "Speed multiplier." },
		},
	},

	Comment = {
		BlockType = "Comment",
		Category = "Utility",
		DisplayName = "Comment",
		Description = "A visual note for documentation. Does not execute.",
		Color = COLORS.Utility,
		Ports = {},
		Properties = {
			{ Key = "Text", Label = "Text", Type = "String", Default = "Note", Tooltip = "Comment text." },
		},
	},

	Print = {
		BlockType = "Print",
		Category = "Utility",
		DisplayName = "Print",
		Description = "Watches a value and prints it when evaluated.",
		Color = COLORS.Utility,
		Pure = false,
		Ports = {
			{ Name = "Watch", Direction = "Input", PortType = "Value", ValueType = "Any" },
		},
		Properties = {
			{ Key = "Label", Label = "Label", Type = "String", Default = "Print", Tooltip = "Label shown in output." },
		},
	},
}

local CATEGORIES = {
	{ Name = "Flow", Types = { "BranchStart", "Wait", "Branch", "Gate", "Condition", "Cancel" } },
	{ Name = "Combat", Types = { "Hitbox", "HitWindow", "ModifyHealth" } },
	{ Name = "Effects", Types = { "Animation", "Sound", "Velocity" } },
	{ Name = "Logic", Types = { "EmitSignal", "Timer", "Counter" } },
	{ Name = "Entity", Types = { "Self", "LastHitTarget", "SelectTarget", "GetDistance", "GetStat", "SetStat", "GetState", "SetState" } },
	{ Name = "Value", Types = { "Constant", "GetHealth", "Compare", "Math", "Random", "Clamp", "Lerp", "Select" } },
	{ Name = "Boolean", Types = { "And", "Or", "Not", "SignalActive", "GetTag" } },
	{ Name = "Advanced", Types = { "SubAction" } },
	{ Name = "Utility", Types = { "Comment", "Print" } },
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

function BlockDefinitions.GetFlowInputs(BlockType: string): { PortDefinition }
	local InputPorts = BlockDefinitions.GetInputPorts(BlockType)
	local FlowPorts: { PortDefinition } = {}
	for _, Port in InputPorts do
		if Port.PortType == "Flow" then
			table.insert(FlowPorts, Port)
		end
	end
	return FlowPorts
end

function BlockDefinitions.GetFlowOutputs(BlockType: string): { PortDefinition }
	local OutputPorts = BlockDefinitions.GetOutputPorts(BlockType)
	local FlowPorts: { PortDefinition } = {}
	for _, Port in OutputPorts do
		if Port.PortType == "Flow" then
			table.insert(FlowPorts, Port)
		end
	end
	return FlowPorts
end

function BlockDefinitions.GetSignalInputs(BlockType: string): { PortDefinition }
	local InputPorts = BlockDefinitions.GetInputPorts(BlockType)
	local SignalPorts: { PortDefinition } = {}
	for _, Port in InputPorts do
		if Port.PortType == "Signal" then
			table.insert(SignalPorts, Port)
		end
	end
	return SignalPorts
end

function BlockDefinitions.GetSignalOutputs(BlockType: string): { PortDefinition }
	local OutputPorts = BlockDefinitions.GetOutputPorts(BlockType)
	local SignalPorts: { PortDefinition } = {}
	for _, Port in OutputPorts do
		if Port.PortType == "Signal" then
			table.insert(SignalPorts, Port)
		end
	end
	return SignalPorts
end

function BlockDefinitions.GetValueInputs(BlockType: string): { PortDefinition }
	local InputPorts = BlockDefinitions.GetInputPorts(BlockType)
	local ValuePorts: { PortDefinition } = {}
	for _, Port in InputPorts do
		if Port.PortType == "Value" then
			table.insert(ValuePorts, Port)
		end
	end
	return ValuePorts
end

function BlockDefinitions.GetValueOutputs(BlockType: string): { PortDefinition }
	local OutputPorts = BlockDefinitions.GetOutputPorts(BlockType)
	local ValuePorts: { PortDefinition } = {}
	for _, Port in OutputPorts do
		if Port.PortType == "Value" then
			table.insert(ValuePorts, Port)
		end
	end
	return ValuePorts
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

function BlockDefinitions.GetWireableProperties(BlockType: string): { PropertyDefinition }
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return {}
	end

	local Wireable: { PropertyDefinition } = {}
	for _, PropertyDef in Definition.Properties do
		if PropertyDef.Wireable then
			table.insert(Wireable, PropertyDef)
		end
	end
	return Wireable
end

function BlockDefinitions.IsPure(BlockType: string): boolean
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return false
	end
	return Definition.Pure == true
end

function BlockDefinitions.GetColors(): { [string]: Color3 }
	return COLORS
end

function BlockDefinitions.GetPortDefinition(BlockType: string, PortName: string, Direction: PortDirection): PortDefinition?
	local Definition = DEFINITIONS[BlockType]
	if not Definition then
		return nil
	end

	for _, Port in Definition.Ports do
		if Port.Name == PortName and Port.Direction == Direction then
			return Port
		end
	end

	return nil
end

return BlockDefinitions