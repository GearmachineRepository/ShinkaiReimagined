--!strict

return {
	ActionId = "SimplePunch",
	DisplayName = "Simple Punch",

	Timeline = {
		{ BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1 },
		{ BlockType = "Wait", Time = 0.1 },
		{ BlockType = "Hitbox", X = 0, Y = 0, Z = 4, SizeX = 5, SizeY = 5, SizeZ = 5, Damage = 8, Stun = 0.2 },
		{ BlockType = "Wait", Time = 0.3 },
	},

	Conditions = {
		OnAir = false,
	},

	Properties = {
		DamageMultiplier = 1,
	},
}