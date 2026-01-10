--!strict

return table.freeze({
	BlockType = table.freeze({
		Wait = "Wait",
		Animation = "Animation",
		Sound = "Sound",
		Velocity = "Velocity",
		Hitbox = "Hitbox",
		HitCancel = "HitCancel",
		Skill = "Skill",
		Branch = "Branch",
		AddHealth = "AddHealth",

		Signal = "Signal",
		AndGate = "AndGate",
		OrGate = "OrGate",
		NotGate = "NotGate",
		Timer = "Timer",
		Counter = "Counter",
	}),

	AttackType = table.freeze({
		Melee = "Melee",
		Projectile = "Projectile",
		Explosion = "Explosion",
		Area = "Area",
	}),

	Skill = table.freeze({
		Activated = "Combat.Skill.Activated",
		Completed = "Combat.Skill.Completed",
		Canceled = "Combat.Skill.Canceled",
		Rejected = "Combat.Skill.Rejected",
		BranchChanged = "Combat.Skill.BranchChanged",
	}),

	Hitbox = table.freeze({
		Created = "Combat.Hitbox.Created",
		Hit = "Combat.Hitbox.Hit",
		Missed = "Combat.Hitbox.Missed",
		Expired = "Combat.Hitbox.Expired",
		Blocked = "Combat.Hitbox.Blocked",
	}),

	Signal = table.freeze({
		Emitted = "Combat.Signal.Emitted",
		Cleared = "Combat.Signal.Cleared",
	}),
})