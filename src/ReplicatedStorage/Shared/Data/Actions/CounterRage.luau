--!strict

return {
	ActionId = "CounterRage",
	DisplayName = "Counter Rage",

	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.1 },
				{ BlockType = "Wait", Time = 0.1 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 4,
					SizeX = 8, SizeY = 6, SizeZ = 8,
					Damage = 10,
					Stun = 0.2,
					Outputs = { OnHit = "SlashHit" },
				},
				{
					BlockType = "Counter",
					Input = "SlashHit",
					Threshold = 3,
					Output = "RageReady",
					Duration = 5,
					ResetOnThreshold = true,
				},
				{
					BlockType = "Timer",
					Input = "RageReady",
					Time = 0.1,
					Output = "TriggerRage",
					OutputDuration = 3,
				},
				{
					BlockType = "Animation",
					AnimationId = "rbxassetid://0",
					Speed = 2,
					RequireSignal = "TriggerRage",
				},
				{
					BlockType = "Sound",
					SoundId = "rbxassetid://0",
					Volume = 1.2,
					RequireSignal = "TriggerRage",
				},
				{
					BlockType = "Velocity",
					RequireSignal = "TriggerRage",
					X = 0, Y = 10, Z = 40,
					Time = 0.2,
					Fade = true,
					Track = true,
				},
				{
					BlockType = "Hitbox",
					RequireSignal = "TriggerRage",
					X = 0, Y = 0, Z = 6,
					SizeX = 12, SizeY = 10, SizeZ = 14,
					Damage = 25,
					Stun = 0.8,
				},
				{ BlockType = "Wait", Time = 0.5 },
			},
		},
	},

	Conditions = {
		OnAir = false,
	},

	Properties = {
		DamageMultiplier = 1,
		KnockbackMultiplier = 1.5,
	},
}