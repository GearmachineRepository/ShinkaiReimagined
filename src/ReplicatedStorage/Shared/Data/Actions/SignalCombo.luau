--!strict

return {
	ActionId = "SignalCombo",
	DisplayName = "Signal Combo",

	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1 },
				{ BlockType = "Wait", Time = 0.1 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 4,
					SizeX = 6, SizeY = 6, SizeZ = 6,
					Damage = 10,
					Stun = 0.25,
					Outputs = { OnHit = "Hit1" },
				},
				{ BlockType = "HitCancel", Time = 0.3, Flip = false, Branch = "SecondHit" },
				{ BlockType = "Wait", Time = 0.4 },
			},
		},

		SecondHit = {
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.2 },
				{ BlockType = "Wait", Time = 0.1 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 5,
					SizeX = 7, SizeY = 6, SizeZ = 7,
					Damage = 12,
					Stun = 0.3,
					Outputs = { OnHit = "Hit2" },
				},
				{
					BlockType = "AndGate",
					Inputs = { "Hit1", "Hit2" },
					Threshold = 2,
					Output = "FullCombo",
					Duration = 2,
				},
				{ BlockType = "HitCancel", Time = 0.3, Flip = false, Branch = "Finisher" },
				{ BlockType = "Wait", Time = 0.3 },
			},
		},

		Finisher = {
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.4 },
				{ BlockType = "Sound", SoundId = "rbxassetid://0", Volume = 1 },
				{ BlockType = "Wait", Time = 0.15 },
				{ BlockType = "Velocity", X = 0, Y = 0, Z = 30, Time = 0.15, Fade = true, Track = true },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 6,
					SizeX = 8, SizeY = 8, SizeZ = 10,
					Damage = 15,
					Stun = 0.5,
				},
				{
					BlockType = "Hitbox",
					RequireSignal = "FullCombo",
					X = 0, Y = 0, Z = 6,
					SizeX = 10, SizeY = 10, SizeZ = 12,
					Damage = 10,
					Stun = 0.3,
				},
				{ BlockType = "Wait", Time = 0.4 },
			},
		},
	},

	Conditions = {
		OnAir = false,
	},

	Properties = {
		DamageMultiplier = 1,
		KnockbackMultiplier = 1,
	},
}