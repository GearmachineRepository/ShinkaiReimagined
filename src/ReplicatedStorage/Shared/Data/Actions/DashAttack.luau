--!strict

return {
	ActionId = "DashAttack",
	DisplayName = "Dash Attack",

	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.2 },
				{ BlockType = "Velocity", X = 0, Y = 0, Z = 50, Time = 0.2, Fade = true, Track = false },
				{ BlockType = "Wait", Time = 0.15 },
				{ BlockType = "Hitbox", X = 0, Y = 0, Z = 5, SizeX = 6, SizeY = 6, SizeZ = 8, Damage = 12, Stun = 0.3 },
				{ BlockType = "HitCancel", Time = 0.4, Flip = false, Branch = "HitConfirm" },
				{ BlockType = "HitCancel", Time = 0.4, Flip = true, Branch = "Whiff" },
			},
		},

		HitConfirm = {
			Timeline = {
				{ BlockType = "Sound", SoundId = "rbxassetid://0", Volume = 0.8 },
				{ BlockType = "Wait", Time = 0.2 },
			},
		},

		Whiff = {
			Timeline = {
				{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 0.6 },
				{ BlockType = "Wait", Time = 0.5 },
			},
		},
	},

	Conditions = {
		OnAir = false,
	},

	Properties = {
		DamageMultiplier = 1,
		KnockbackMultiplier = 1.2,
	},
}