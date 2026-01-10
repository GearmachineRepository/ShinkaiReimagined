--!strict

local TemplateSkills = {}

TemplateSkills.ThreeHitCombo = {
	SkillId = "ThreeHitCombo",
	DisplayName = "Three Hit Combo",
	IsPlayerMade = true,
	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "", Speed = 1 },
				{ BlockType = "Sound", SoundId = "", Volume = 0.8 },
				{ BlockType = "Wait", Time = 0.15 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 4,
					SizeX = 5, SizeY = 5, SizeZ = 5,
					Damage = 8,
					Stun = 0.3,
					AttackType = "Melee",
					Blockable = true,
					CancelEnemy = false,
					Outputs = {
						OnHit = "Hit1",
						OnMiss = "Whiff",
						Duration = 0.1,
					},
				},
				{ BlockType = "HitCancel", Time = 0.4, Endlag = 0.2, Branch = "Whiff" },
			},
		},
		Hit1 = {
			Entry = false,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "", Speed = 1.1 },
				{ BlockType = "Sound", SoundId = "", Volume = 0.8 },
				{ BlockType = "Wait", Time = 0.12 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 4,
					SizeX = 5, SizeY = 5, SizeZ = 5,
					Damage = 10,
					Stun = 0.35,
					AttackType = "Melee",
					Blockable = true,
					CancelEnemy = false,
					Outputs = {
						OnHit = "Hit2",
						OnMiss = "Whiff",
						Duration = 0.1,
					},
				},
				{ BlockType = "HitCancel", Time = 0.35, Endlag = 0.25, Branch = "Whiff" },
			},
		},
		Hit2 = {
			Entry = false,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "", Speed = 1 },
				{ BlockType = "Sound", SoundId = "", Volume = 1 },
				{ BlockType = "Velocity", X = 0, Y = 0, Z = 20, Time = 0.15, Fade = true },
				{ BlockType = "Wait", Time = 0.2 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 5,
					SizeX = 6, SizeY = 6, SizeZ = 6,
					Damage = 15,
					Stun = 0.5,
					AttackType = "Melee",
					Blockable = true,
					CancelEnemy = true,
				},
				{ BlockType = "Wait", Time = 0.4 },
			},
		},
		Whiff = {
			Entry = false,
			Timeline = {
				{ BlockType = "Wait", Time = 0.35 },
			},
		},
	},
}

TemplateSkills.DashAttack = {
	SkillId = "DashAttack",
	DisplayName = "Dash Attack",
	IsPlayerMade = true,
	Timeline = {
		{ BlockType = "Animation", AnimationId = "", Speed = 1.2 },
		{ BlockType = "Sound", SoundId = "", Volume = 0.6 },
		{ BlockType = "Velocity", X = 0, Y = 5, Z = 40, Time = 0.25, Fade = true },
		{ BlockType = "Wait", Time = 0.1 },
		{
			BlockType = "Hitbox",
			X = 0, Y = 0, Z = 3,
			SizeX = 4, SizeY = 4, SizeZ = 8,
			Damage = 12,
			Stun = 0.4,
			AttackType = "Melee",
			Blockable = true,
			CancelEnemy = true,
		},
		{ BlockType = "Wait", Time = 0.3 },
	},
}

TemplateSkills.CounterStance = {
	SkillId = "CounterStance",
	DisplayName = "Counter Stance",
	IsPlayerMade = true,
	Branches = {
		Main = {
			Entry = true,
			Timeline = {
				{ BlockType = "Animation", AnimationId = "", Speed = 1, Loop = true },
				{ BlockType = "Signal", SignalId = "Blocking", Duration = 2 },
				{ BlockType = "Wait", Time = 0.5 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 2,
					SizeX = 8, SizeY = 8, SizeZ = 4,
					Damage = 0,
					Stun = 0,
					AttackType = "Counter",
					Blockable = false,
					Outputs = {
						OnHit = "CounterAttack",
						Duration = 1.5,
					},
				},
				{ BlockType = "Wait", Time = 1.5 },
				{ BlockType = "Branch", BranchName = "EndStance" },
			},
		},
		CounterAttack = {
			Entry = false,
			Timeline = {
				{ BlockType = "Signal", SignalId = "Blocking", Clear = true },
				{ BlockType = "Animation", AnimationId = "", Speed = 1.5 },
				{ BlockType = "Sound", SoundId = "", Volume = 1 },
				{ BlockType = "Wait", Time = 0.1 },
				{
					BlockType = "Hitbox",
					X = 0, Y = 0, Z = 5,
					SizeX = 6, SizeY = 6, SizeZ = 6,
					Damage = 20,
					Stun = 0.8,
					AttackType = "Counter",
					Blockable = false,
					CancelEnemy = true,
				},
				{ BlockType = "Velocity", X = 0, Y = 10, Z = 30, Time = 0.2, Fade = true },
				{ BlockType = "Wait", Time = 0.5 },
			},
		},
		EndStance = {
			Entry = false,
			Timeline = {
				{ BlockType = "Signal", SignalId = "Blocking", Clear = true },
				{ BlockType = "Wait", Time = 0.2 },
			},
		},
	},
}

TemplateSkills.SignalCombo = {
	SkillId = "SignalCombo",
	DisplayName = "Signal Combo",
	IsPlayerMade = true,
	Timeline = {
		{ BlockType = "Animation", AnimationId = "", Speed = 1 },
		{ BlockType = "Wait", Time = 0.2 },
		{
			BlockType = "Hitbox",
			X = 0, Y = 0, Z = 4,
			SizeX = 5, SizeY = 5, SizeZ = 5,
			Damage = 10,
			Stun = 0.3,
			AttackType = "Melee",
			Blockable = true,
			Outputs = {
				OnHit = "CanFollowUp",
				Duration = 0.5,
			},
		},
		{ BlockType = "Wait", Time = 0.3 },
		{
			BlockType = "Animation",
			AnimationId = "",
			Speed = 1.2,
			RequireSignal = "CanFollowUp",
		},
		{
			BlockType = "Wait",
			Time = 0.15,
			RequireSignal = "CanFollowUp",
		},
		{
			BlockType = "Hitbox",
			X = 0, Y = 0, Z = 5,
			SizeX = 6, SizeY = 6, SizeZ = 6,
			Damage = 15,
			Stun = 0.5,
			AttackType = "Melee",
			Blockable = true,
			CancelEnemy = true,
			RequireSignal = "CanFollowUp",
		},
		{ BlockType = "Wait", Time = 0.4 },
	},
}

function TemplateSkills.GetAll(): { [string]: any }
	return {
		ThreeHitCombo = TemplateSkills.ThreeHitCombo,
		DashAttack = TemplateSkills.DashAttack,
		CounterStance = TemplateSkills.CounterStance,
		SignalCombo = TemplateSkills.SignalCombo,
	}
end

function TemplateSkills.Get(TemplateId: string): any?
	return TemplateSkills[TemplateId]
end

return TemplateSkills