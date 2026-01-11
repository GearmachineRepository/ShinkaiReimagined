--!strict

return {
	ActionId = "AirDive",
	DisplayName = "Air Dive",

	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.5 },
				{ BlockType = "Sound", SoundId = "rbxassetid://0", Volume = 0.6 },
				{ BlockType = "Velocity", X = 0, Y = -60, Z = 30, Time = 0.3, Fade = false, Track = true },
				{ BlockType = "Wait", Time = 0.1 },
				{
					BlockType = "Hitbox",
					X = 0, Y = -2, Z = 3,
					SizeX = 5, SizeY = 8, SizeZ = 5,
					Damage = 18,
					Stun = 0.5,
				},
				{ BlockType = "HitCancel", Time = 0.5, Flip = false, Branch = "Landing" },
				{ BlockType = "HitCancel", Time = 0.5, Flip = true, Branch = "HardLanding" },
			},
		},

		Landing = {
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1 },
				{ BlockType = "Sound", SoundId = "rbxassetid://0", Volume = 0.8 },
				{ BlockType = "Wait", Time = 0.2 },
			},
		},

		HardLanding = {
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 0.5 },
				{ BlockType = "Wait", Time = 0.6 },
			},
		},
	},

	Conditions = {
		OnAir = true,
	},

	Properties = {
		DamageMultiplier = 1.2,
		KnockbackMultiplier = 1,
	},
}