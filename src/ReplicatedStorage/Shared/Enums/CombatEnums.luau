--!strict

return table.freeze({
	BlockType = table.freeze({
		BranchStart = "BranchStart",
		Wait = "Wait",
		Branch = "Branch",
		Gate = "Gate",
		Condition = "Condition",
		Animation = "Animation",
		Sound = "Sound",
		Velocity = "Velocity",
		Hitbox = "Hitbox",
		HitCancel = "HitCancel",
		AddHealth = "AddHealth",
		Signal = "Signal",
		AndGate = "AndGate",
		OrGate = "OrGate",
		NotGate = "NotGate",
		Timer = "Timer",
		Counter = "Counter",
		SubAction = "SubAction",
		Action = "Action",
		Comment = "Comment",
	}),

	ConditionCheck = table.freeze({
		IsGrounded = "IsGrounded",
		IsAirborne = "IsAirborne",
		HasTarget = "HasTarget",
		IsBlocking = "IsBlocking",
		IsStunned = "IsStunned",
		HealthAbove = "HealthAbove",
		HealthBelow = "HealthBelow",
		TargetInRange = "TargetInRange",
	}),

	AttackType = table.freeze({
		Melee = "Melee",
		Projectile = "Projectile",
		Explosion = "Explosion",
		Area = "Area",
	}),

	Action = table.freeze({
		Activated = "Combat.Action.Activated",
		Completed = "Combat.Action.Completed",
		Canceled = "Combat.Action.Canceled",
		Rejected = "Combat.Action.Rejected",
		BranchChanged = "Combat.Action.BranchChanged",
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