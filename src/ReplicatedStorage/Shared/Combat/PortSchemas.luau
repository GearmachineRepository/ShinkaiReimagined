--!strict

local PortSchemas = {
    Wait = {
        Outputs = {},
    },

    Animation = {
        Outputs = { "OnComplete" },
    },

    Sound = {
        Outputs = {},
    },

    Velocity = {
        Outputs = {},
    },

    Hitbox = {
        Outputs = { "OnHit", "OnMiss" },
    },

    HitCancel = {
        Outputs = {},
    },

    Skill = {
        Outputs = { "OnComplete" },
    },

    Branch = {
        Outputs = {},
    },

    AddHealth = {
        Outputs = {},
    },

    Signal = {
        Outputs = {},
    },

    AndGate = {
        Outputs = { "OnPass" },
    },

    OrGate = {
        Outputs = { "OnPass" },
    },

    NotGate = {
        Outputs = { "OnPass" },
    },

    Timer = {
        Outputs = { "OnExpired" },
    },

    Counter = {
        Outputs = { "OnThreshold" },
    },
}

return PortSchemas