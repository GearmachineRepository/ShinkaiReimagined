--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enums = require(Shared.Enums)
local PortSchemas = require(script.Parent.PortSchemas)

local SkillValidator = {}

local MAX_BLOCKS = 50
local MAX_BRANCHES = 10
local MAX_SIGNAL_LENGTH = 32
local MAX_ID_LENGTH = 64
local MAX_DAMAGE = 100
local MAX_STUN = 5
local MAX_WAIT = 10
local MAX_COMMENTS = 50

local ALLOWED_BLOCK_TYPES: { [string]: boolean } = {}
for BlockType in pairs(Enums.Combat.BlockType) do
    ALLOWED_BLOCK_TYPES[BlockType] = true
end

local function ValidateString(Value: any, MaxLength: number): string?
    if type(Value) ~= "string" then
        return nil
    end
    if #Value == 0 then
        return nil
    end
    if #Value > MaxLength then
        return string.sub(Value, 1, MaxLength)
    end
    return Value
end

local function ValidateNumber(Value: any, Min: number, Max: number, Default: number?): number?
    if type(Value) ~= "number" then
        return Default
    end
    return math.clamp(Value, Min, Max)
end

local function ValidateBoolean(Value: any, Default: boolean): boolean
    if type(Value) == "boolean" then
        return Value
    end
    return Default
end

local function ValidateEditorPosition(Value: any): { X: number, Y: number }?
    if type(Value) ~= "table" then
        return nil
    end
    if type(Value.X) ~= "number" or type(Value.Y) ~= "number" then
        return nil
    end
    return {
        X = Value.X,
        Y = Value.Y,
    }
end

local function ValidateBlock(Block: any): any?
    if type(Block) ~= "table" then
        return nil
    end

    local BlockType = Block.BlockType
    if not ALLOWED_BLOCK_TYPES[BlockType] then
        return nil
    end

    local Clean: { [string]: any } = {
        BlockType = BlockType,
    }

    Clean.BlockId = ValidateString(Block.BlockId, MAX_ID_LENGTH)
    Clean.EditorPosition = ValidateEditorPosition(Block.EditorPosition)

    if Block.RequireSignal then
        if type(Block.RequireSignal) == "string" then
            Clean.RequireSignal = ValidateString(Block.RequireSignal, MAX_SIGNAL_LENGTH)
        elseif type(Block.RequireSignal) == "table" then
            local Signals = {}
            for _, Signal in Block.RequireSignal do
                if #Signals >= 8 then
                    break
                end
                local ValidSignal = ValidateString(Signal, MAX_SIGNAL_LENGTH)
                if ValidSignal then
                    table.insert(Signals, ValidSignal)
                end
            end
            if #Signals > 0 then
                Clean.RequireSignal = Signals
            end
        end
    end

    Clean.RequireAll = ValidateBoolean(Block.RequireAll, true)

    if BlockType == "Wait" then
        Clean.Time = ValidateNumber(Block.Time, 0, MAX_WAIT, 0.1)

    elseif BlockType == "Hitbox" then
        Clean.X = ValidateNumber(Block.X, -20, 20, 0)
        Clean.Y = ValidateNumber(Block.Y, -20, 20, 0)
        Clean.Z = ValidateNumber(Block.Z, -20, 20, 4)
        Clean.SizeX = ValidateNumber(Block.SizeX, 1, 20, 6)
        Clean.SizeY = ValidateNumber(Block.SizeY, 1, 20, 6)
        Clean.SizeZ = ValidateNumber(Block.SizeZ, 1, 20, 6)
        Clean.Damage = ValidateNumber(Block.Damage, 0, MAX_DAMAGE, 5)
        Clean.Stun = ValidateNumber(Block.Stun, 0, MAX_STUN, 0.2)
        Clean.AttackType = ValidateString(Block.AttackType, 16) or "Melee"
        Clean.Blockable = ValidateBoolean(Block.Blockable, true)
        Clean.Block360 = ValidateBoolean(Block.Block360, false)
        Clean.CancelEnemy = ValidateBoolean(Block.CancelEnemy, true)

        if type(Block.Outputs) == "table" then
            Clean.Outputs = {
                OnHit = ValidateString(Block.Outputs.OnHit, MAX_SIGNAL_LENGTH),
                OnMiss = ValidateString(Block.Outputs.OnMiss, MAX_SIGNAL_LENGTH),
                Duration = ValidateNumber(Block.Outputs.Duration, 0, 10, nil),
            }
        end

    elseif BlockType == "Animation" then
        Clean.AnimationId = ValidateString(Block.AnimationId, 64)
        Clean.Speed = ValidateNumber(Block.Speed, 0.1, 3, 1)
        Clean.Loop = ValidateBoolean(Block.Loop, false)

    elseif BlockType == "Sound" then
        Clean.SoundId = ValidateString(Block.SoundId, 64)
        Clean.Volume = ValidateNumber(Block.Volume, 0, 2, 1)
        Clean.Speed = ValidateNumber(Block.Speed, 0.1, 3, 1)

    elseif BlockType == "Velocity" then
        Clean.X = ValidateNumber(Block.X, -100, 100, 0)
        Clean.Y = ValidateNumber(Block.Y, -100, 100, 0)
        Clean.Z = ValidateNumber(Block.Z, -100, 100, 0)
        Clean.Time = ValidateNumber(Block.Time, 0, 2, 0.2)
        Clean.Fade = ValidateBoolean(Block.Fade, false)
        Clean.Track = ValidateBoolean(Block.Track, false)

    elseif BlockType == "Signal" then
        Clean.SignalId = ValidateString(Block.SignalId, MAX_SIGNAL_LENGTH)
        Clean.Duration = ValidateNumber(Block.Duration, 0, 10, nil)
        Clean.Clear = ValidateBoolean(Block.Clear, false)

    elseif BlockType == "AndGate" or BlockType == "OrGate" then
        if type(Block.Inputs) == "table" then
            Clean.Inputs = {}
            for _, Input in Block.Inputs do
                if #Clean.Inputs >= 8 then
                    break
                end
                local ValidInput = ValidateString(Input, MAX_SIGNAL_LENGTH)
                if ValidInput then
                    table.insert(Clean.Inputs, ValidInput)
                end
            end
        end
        Clean.Threshold = ValidateNumber(Block.Threshold, 1, 8, nil)
        Clean.Output = ValidateString(Block.Output, MAX_SIGNAL_LENGTH)
        Clean.Duration = ValidateNumber(Block.Duration, 0, 10, nil)

    elseif BlockType == "NotGate" then
        Clean.Input = ValidateString(Block.Input, MAX_SIGNAL_LENGTH)
        Clean.Output = ValidateString(Block.Output, MAX_SIGNAL_LENGTH)
        Clean.Duration = ValidateNumber(Block.Duration, 0, 10, nil)

    elseif BlockType == "Timer" then
        Clean.Input = ValidateString(Block.Input, MAX_SIGNAL_LENGTH)
        Clean.Time = ValidateNumber(Block.Time, 0.1, MAX_WAIT, 1)
        Clean.Output = ValidateString(Block.Output, MAX_SIGNAL_LENGTH)
        Clean.OutputDuration = ValidateNumber(Block.OutputDuration, 0, 10, nil)

    elseif BlockType == "Counter" then
        Clean.Input = ValidateString(Block.Input, MAX_SIGNAL_LENGTH)
        Clean.Threshold = ValidateNumber(Block.Threshold, 1, 100, 3)
        Clean.Output = ValidateString(Block.Output, MAX_SIGNAL_LENGTH)
        Clean.Duration = ValidateNumber(Block.Duration, 0, 10, nil)
        Clean.ResetOnThreshold = ValidateBoolean(Block.ResetOnThreshold, true)

    elseif BlockType == "HitCancel" then
        Clean.Time = ValidateNumber(Block.Time, 0, 5, 0.5)
        Clean.Flip = ValidateBoolean(Block.Flip, false)
        Clean.Endlag = ValidateNumber(Block.Endlag, 0, 2, 0)
        Clean.Branch = ValidateString(Block.Branch, 32)

    elseif BlockType == "AddHealth" then
        Clean.Amount = ValidateNumber(Block.Amount, -50, 50, 5)

    elseif BlockType == "Branch" then
        Clean.BranchName = ValidateString(Block.BranchName, 32)

    elseif BlockType == "Skill" then
        Clean.SkillId = ValidateString(Block.SkillId, 32)
        Clean.Speed = ValidateNumber(Block.Speed, 0.1, 3, 1)
        Clean.CancelLast = ValidateBoolean(Block.CancelLast, false)
        Clean.HoldFor = ValidateNumber(Block.HoldFor, 0, 5, 0)
    end

    return Clean
end

local function ValidateTimeline(Timeline: any): { any }?
    if type(Timeline) ~= "table" then
        return nil
    end

    local Clean = {}
    for _, Block in Timeline do
        if #Clean >= MAX_BLOCKS then
            break
        end

        local ValidBlock = ValidateBlock(Block)
        if ValidBlock then
            table.insert(Clean, ValidBlock)
        end
    end

    return Clean
end

local function ValidateBranch(Branch: any): any?
    if type(Branch) ~= "table" then
        return nil
    end

    local Timeline = ValidateTimeline(Branch.Timeline)
    if not Timeline then
        return nil
    end

    return {
        Entry = Branch.Entry == true,
        Timeline = Timeline,
    }
end

local function ValidateWire(Wire: any): any?
    if type(Wire) ~= "table" then
        return nil
    end

    local WireId = ValidateString(Wire.WireId, MAX_ID_LENGTH)
    local FromNodeId = ValidateString(Wire.FromNodeId, MAX_ID_LENGTH)
    local FromPortName = ValidateString(Wire.FromPortName, 32)
    local ToNodeId = ValidateString(Wire.ToNodeId, MAX_ID_LENGTH)
    local ToPortName = ValidateString(Wire.ToPortName, 32)
    local WireType = ValidateString(Wire.WireType, 16)

    if not FromNodeId or not FromPortName or not ToNodeId or not ToPortName then
        return nil
    end

    return {
        WireId = WireId,
        FromNodeId = FromNodeId,
        FromPortName = FromPortName,
        ToNodeId = ToNodeId,
        ToPortName = ToPortName,
        WireType = WireType or "Flow",
    }
end

local function ValidateComment(CommentData: any): any?
    if type(CommentData) ~= "table" then
        return nil
    end

    local CommentId = ValidateString(CommentData.CommentId, MAX_ID_LENGTH)
    if not CommentId then
        return nil
    end

    local Title = ValidateString(CommentData.Title, 64) or "Comment"
    local Text = CommentData.Text
    if type(Text) ~= "string" then
        Text = ""
    elseif #Text > 1000 then
        Text = string.sub(Text, 1, 1000)
    end

    local Color = { R = 0.3, G = 0.78, B = 0.63 }
    if type(CommentData.Color) == "table" then
        Color.R = ValidateNumber(CommentData.Color.R, 0, 1, 0.3) or 0.3
        Color.G = ValidateNumber(CommentData.Color.G, 0, 1, 0.78) or 0.78
        Color.B = ValidateNumber(CommentData.Color.B, 0, 1, 0.63) or 0.63
    end

    local Position = { X = 0, Y = 0 }
    if type(CommentData.Position) == "table" then
        Position.X = ValidateNumber(CommentData.Position.X, -10000, 10000, 0) or 0
        Position.Y = ValidateNumber(CommentData.Position.Y, -10000, 10000, 0) or 0
    end

    local Size = { X = 300, Y = 150 }
    if type(CommentData.Size) == "table" then
        Size.X = ValidateNumber(CommentData.Size.X, 150, 2000, 300) or 300
        Size.Y = ValidateNumber(CommentData.Size.Y, 80, 2000, 150) or 150
    end

    return {
        CommentId = CommentId,
        Title = Title,
        Text = Text,
        Color = Color,
        Position = Position,
        Size = Size,
    }
end

local function ValidateEditorData(EditorData: any): any?
    if type(EditorData) ~= "table" then
        return nil
    end

    local Clean: { [string]: any } = {}

    if type(EditorData.Wires) == "table" then
        Clean.Wires = {}
        for BranchName, BranchWires in EditorData.Wires do
            local ValidBranchName = ValidateString(BranchName, 32)
            if ValidBranchName and type(BranchWires) == "table" then
                local ValidWires = {}
                for _, Wire in BranchWires do
                    local ValidWire = ValidateWire(Wire)
                    if ValidWire then
                        table.insert(ValidWires, ValidWire)
                    end
                end
                if #ValidWires > 0 then
                    Clean.Wires[ValidBranchName] = ValidWires
                end
            end
        end
    end

    if type(EditorData.Comments) == "table" then
        Clean.Comments = {}
        for BranchName, BranchComments in EditorData.Comments do
            local ValidBranchName = ValidateString(BranchName, 32)
            if ValidBranchName and type(BranchComments) == "table" then
                local ValidComments = {}
                for _, CommentData in BranchComments do
                    if #ValidComments >= MAX_COMMENTS then
                        break
                    end
                    local ValidComment = ValidateComment(CommentData)
                    if ValidComment then
                        table.insert(ValidComments, ValidComment)
                    end
                end
                if #ValidComments > 0 then
                    Clean.Comments[ValidBranchName] = ValidComments
                end
            end
        end
    end

    return Clean
end

function SkillValidator.Validate(RawSkill: any): any?
    if type(RawSkill) ~= "table" then
        return nil
    end

    local SkillId = RawSkill.SkillId
    if type(SkillId) ~= "string" then
        SkillId = ""
    elseif #SkillId > 64 then
        SkillId = string.sub(SkillId, 1, 64)
    end

    local DisplayName = ValidateString(RawSkill.DisplayName, 48)
    if not DisplayName then
        return nil
    end

    local Clean: { [string]: any } = {
        SkillId = SkillId,
        DisplayName = DisplayName,
        IsPlayerMade = true,
    }

    if RawSkill.Timeline then
        local Timeline = ValidateTimeline(RawSkill.Timeline)
        if not Timeline or #Timeline == 0 then
            return nil
        end
        Clean.Timeline = Timeline

    elseif RawSkill.Branches then
        if type(RawSkill.Branches) ~= "table" then
            return nil
        end

        Clean.Branches = {}
        local BranchCount = 0
        local HasEntry = false

        for BranchName, BranchData in RawSkill.Branches do
            if BranchCount >= MAX_BRANCHES then
                break
            end

            local ValidName = ValidateString(BranchName, 32)
            if ValidName then
                local ValidBranch = ValidateBranch(BranchData)
                if ValidBranch then
                    Clean.Branches[ValidName] = ValidBranch
                    BranchCount = BranchCount + 1
                    if ValidBranch.Entry then
                        HasEntry = true
                    end
                end
            end
        end

        if BranchCount == 0 then
            return nil
        end

        if not HasEntry and Clean.Branches["Main"] then
            Clean.Branches["Main"].Entry = true
        end
    end

    if not Clean.Timeline and not Clean.Branches then
        return nil
    end

    if RawSkill.Conditions and type(RawSkill.Conditions) == "table" then
        Clean.Conditions = {
            OnAir = if type(RawSkill.Conditions.OnAir) == "boolean"
                then RawSkill.Conditions.OnAir
                else nil,
        }
    end

    Clean.Properties = {
        DamageMultiplier = 1,
        KnockbackMultiplier = 1,
    }

    Clean.EditorData = ValidateEditorData(RawSkill.EditorData)

    return Clean
end

function SkillValidator.ValidateBlock(Block: any): any?
    return ValidateBlock(Block)
end

function SkillValidator.GetPortSchema(BlockType: string): { Outputs: { string } }?
    return PortSchemas[BlockType]
end

function SkillValidator.GetAllPortSchemas(): { [string]: { Outputs: { string } } }
    return PortSchemas
end

return SkillValidator
