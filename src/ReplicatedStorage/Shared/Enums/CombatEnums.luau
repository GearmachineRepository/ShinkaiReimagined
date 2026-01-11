--!strict

return table.freeze({
    BlockType = table.freeze({
        Wait = "Wait",
        Animation = "Animation",
        Sound = "Sound",
        Velocity = "Velocity",
        Hitbox = "Hitbox",
        HitCancel = "HitCancel",
        Action = "Action",
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