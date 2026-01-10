--!strict

return {
    SkillId = "AdvancedCombo",
    DisplayName = "Advanced Combo",

    Branches = {
        Main = {
            Entry = true,
            Timeline = {
                { BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1 },
                { BlockType = "Wait", Time = 0.1 },

                {
                    BlockType = "Hitbox",
                    BlockId = "FirstHit",
                    X = 0, Y = 0, Z = 4,
                    SizeX = 6, SizeY = 6, SizeZ = 6,
                    Damage = 8,
                    Stun = 0.2,

                    Outputs = {
                        OnHit = "FirstHitConnected",
                        OnMiss = "FirstHitMissed",
                    },
                },

                {
                    BlockType = "Timer",
                    Input = "FirstHitConnected",
                    Time = 0.8,
                    Output = "ComboWindowExpired",
                },

                { BlockType = "HitCancel", Time = 0.5, Flip = false, Branch = "SecondHit" },
                { BlockType = "HitCancel", Time = 0.5, Flip = true, Branch = "WhiffRecovery" },
            },
        },

        SecondHit = {
            Timeline = {
                { BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 1.25 },
                { BlockType = "Wait", Time = 0.15 },

                {
                    BlockType = "Hitbox",
                    BlockId = "SecondHit",
                    X = 0, Y = 0, Z = 4,
                    SizeX = 7, SizeY = 6, SizeZ = 7,
                    Damage = 12,
                    Stun = 0.35,

                    Outputs = {
                        OnHit = "SecondHitConnected",
                    },
                },

                {
                    BlockType = "AndGate",
                    Inputs = { "FirstHitConnected", "SecondHitConnected" },
                    Threshold = 2,
                    Output = "FullComboConfirmed",
                },

                {
                    BlockType = "Animation",
                    AnimationId = "rbxassetid://0",
                    Speed = 1.5,
                    RequireSignal = "FullComboConfirmed",
                },

                {
                    BlockType = "Hitbox",
                    BlockId = "BonusFinisher",
                    RequireSignal = "FullComboConfirmed",
                    X = 0, Y = 0, Z = 5,
                    SizeX = 8, SizeY = 8, SizeZ = 8,
                    Damage = 20,
                    Stun = 0.5,
                },
            },
        },

        WhiffRecovery = {
            Timeline = {
                { BlockType = "Animation", AnimationId = "rbxassetid://0", Speed = 0.75 },
                { BlockType = "Wait", Time = 0.5 },
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