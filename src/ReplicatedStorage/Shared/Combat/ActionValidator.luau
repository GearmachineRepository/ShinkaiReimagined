--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlockDefinitions = require(script.Parent.BlockDefinitions)
local Enums = require(Shared.Enums)

local ActionValidator = {}

type BlockDefinition = BlockDefinitions.BlockDefinition
type PortDefintion = BlockDefinitions.PortDefinition

local MAX_BLOCKS = 50
local MAX_BRANCHES = 10
local MAX_SIGNAL_LENGTH = 32
local MAX_ID_LENGTH = 64
local MAX_DAMAGE = 100
local MAX_STUN = 5
local MAX_WAIT = 10
local MAX_COMMENTS = 50
local MAX_WIRES = 200

local ALLOWED_BLOCK_TYPES: { [string]: boolean } = {}
for BlockType in pairs(Enums.Combat.BlockType) do
	ALLOWED_BLOCK_TYPES[BlockType] = true
end

ALLOWED_BLOCK_TYPES["BranchStart"] = true
ALLOWED_BLOCK_TYPES["Constant"] = true
ALLOWED_BLOCK_TYPES["Compare"] = true
ALLOWED_BLOCK_TYPES["Math"] = true
ALLOWED_BLOCK_TYPES["Random"] = true
ALLOWED_BLOCK_TYPES["GetHealth"] = true
ALLOWED_BLOCK_TYPES["GetDistance"] = true
ALLOWED_BLOCK_TYPES["GetTag"] = true
ALLOWED_BLOCK_TYPES["SignalToBool"] = true
ALLOWED_BLOCK_TYPES["Clamp"] = true
ALLOWED_BLOCK_TYPES["Lerp"] = true
ALLOWED_BLOCK_TYPES["Abs"] = true
ALLOWED_BLOCK_TYPES["Negate"] = true
ALLOWED_BLOCK_TYPES["BoolNot"] = true
ALLOWED_BLOCK_TYPES["BoolAnd"] = true
ALLOWED_BLOCK_TYPES["BoolOr"] = true

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

local function ValidateStringAllowEmpty(Value: any, MaxLength: number): string?
	if type(Value) ~= "string" then
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
		X = math.clamp(Value.X, -10000, 10000),
		Y = math.clamp(Value.Y, -10000, 10000),
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

	elseif BlockType == "Action" or BlockType == "SubAction" then
		Clean.ActionId = ValidateString(Block.ActionId, 32)
		Clean.Speed = ValidateNumber(Block.Speed, 0.1, 3, 1)
		Clean.CancelLast = ValidateBoolean(Block.CancelLast, false)
		Clean.HoldFor = ValidateNumber(Block.HoldFor, 0, 5, 0)

	elseif BlockType == "Constant" then
		Clean.Type = ValidateString(Block.Type, 16) or "Number"
		Clean.NumberValue = ValidateNumber(Block.NumberValue, -9999, 9999, 0)
		Clean.BooleanValue = ValidateBoolean(Block.BooleanValue, false)
		Clean.StringValue = ValidateStringAllowEmpty(Block.StringValue, 64) or ""

	elseif BlockType == "Compare" then
		Clean.A = ValidateNumber(Block.A, -9999, 9999, 0)
		Clean.B = ValidateNumber(Block.B, -9999, 9999, 0)
		Clean.Operator = ValidateString(Block.Operator, 4) or ">"

	elseif BlockType == "Math" then
		Clean.A = ValidateNumber(Block.A, -9999, 9999, 0)
		Clean.B = ValidateNumber(Block.B, -9999, 9999, 0)
		Clean.Operator = ValidateString(Block.Operator, 4) or "+"

	elseif BlockType == "Random" then
		Clean.Min = ValidateNumber(Block.Min, -9999, 9999, 0)
		Clean.Max = ValidateNumber(Block.Max, -9999, 9999, 1)
		Clean.Integer = ValidateBoolean(Block.Integer, false)

	elseif BlockType == "GetHealth" then
		Clean.Target = ValidateString(Block.Target, 16) or "Self"

	elseif BlockType == "GetTag" then
		Clean.Tag = ValidateStringAllowEmpty(Block.Tag, 32) or ""

	elseif BlockType == "Clamp" then
		Clean.Value = ValidateNumber(Block.Value, -9999, 9999, 0)
		Clean.Min = ValidateNumber(Block.Min, -9999, 9999, 0)
		Clean.Max = ValidateNumber(Block.Max, -9999, 9999, 1)

	elseif BlockType == "Lerp" then
		Clean.From = ValidateNumber(Block.From, -9999, 9999, 0)
		Clean.To = ValidateNumber(Block.To, -9999, 9999, 1)
		Clean.Alpha = ValidateNumber(Block.Alpha, 0, 1, 0.5)

	elseif BlockType == "Abs" or BlockType == "Negate" then
		Clean.Value = ValidateNumber(Block.Value, -9999, 9999, 0)

	elseif BlockType == "BoolNot" then
		Clean.Value = ValidateBoolean(Block.Value, false)

	elseif BlockType == "BoolAnd" or BlockType == "BoolOr" then
		Clean.A = ValidateBoolean(Block.A, false)
		Clean.B = ValidateBoolean(Block.B, false)
	end

	return Clean
end

local function ValidateNode(NodeId: string, NodeData: any): any?
	if type(NodeData) ~= "table" then
		return nil
	end

	local BlockType = NodeData.BlockType
	if not ALLOWED_BLOCK_TYPES[BlockType] then
		return nil
	end

	local Clean: { [string]: any } = {
		NodeId = NodeId,
		BlockType = BlockType,
	}

	Clean.EditorPosition = ValidateEditorPosition(NodeData.EditorPosition)

	if BlockType == "BranchStart" then
		return Clean
	end

	local BlockData: any = { BlockType = BlockType }
	for Key, Value in NodeData do
		if Key ~= "NodeId" and Key ~= "EditorPosition" then
			BlockData[Key] = Value
		end
	end

	local ValidatedBlock = ValidateBlock(BlockData)
	if not ValidatedBlock then
		return nil
	end

	for Key, Value in ValidatedBlock do
		if Key ~= "BlockType" then
			Clean[Key] = Value
		end
	end

	return Clean
end

local function ValidateGraphWire(Wire: any): any?
	if type(Wire) ~= "table" then
		return nil
	end

	local FromNode = ValidateString(Wire.FromNode, MAX_ID_LENGTH)
	local FromPort = ValidateString(Wire.FromPort, 32)
	local ToNode = ValidateString(Wire.ToNode, MAX_ID_LENGTH)
	local ToPort = ValidateString(Wire.ToPort, 32)

	if not FromNode or not FromPort or not ToNode or not ToPort then
		return nil
	end

	return {
		WireId = ValidateString(Wire.WireId, MAX_ID_LENGTH),
		FromNode = FromNode,
		FromPort = FromPort,
		ToNode = ToNode,
		ToPort = ToPort,
	}
end

local function ValidateGraphBranch(Branch: any): any?
	if type(Branch) ~= "table" then
		return nil
	end

	if type(Branch.Nodes) ~= "table" then
		return nil
	end

	local Clean: { [string]: any } = {
		Entry = Branch.Entry == true,
		Nodes = {},
		Wires = {},
	}

	local NodeCount = 0
	local HasBranchStart = false

	for NodeId, NodeData in Branch.Nodes do
		if NodeCount >= MAX_BLOCKS then
			break
		end

		local ValidNodeId = ValidateString(NodeId, MAX_ID_LENGTH)
		if ValidNodeId then
			local ValidNode = ValidateNode(ValidNodeId, NodeData)
			if ValidNode then
				Clean.Nodes[ValidNodeId] = ValidNode
				NodeCount = NodeCount + 1

				if ValidNode.BlockType == "BranchStart" then
					HasBranchStart = true
				end
			end
		end
	end

	if NodeCount == 0 then
		return nil
	end

	if not HasBranchStart then
		return nil
	end

	if type(Branch.Wires) == "table" then
		local WireCount = 0
		for _, WireData in Branch.Wires do
			if WireCount >= MAX_WIRES then
				break
			end

			local ValidWire = ValidateGraphWire(WireData)
			if ValidWire then
				if Clean.Nodes[ValidWire.FromNode] and Clean.Nodes[ValidWire.ToNode] then
					table.insert(Clean.Wires, ValidWire)
					WireCount = WireCount + 1
				end
			end
		end
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

local function ValidateLegacyBranch(Branch: any): any?
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

local function IsGraphFormat(RawAction: any): boolean
	if RawAction.Branches then
		for _, BranchData in RawAction.Branches do
			if type(BranchData) == "table" and BranchData.Nodes then
				return true
			end
		end
	end
	return false
end

function ActionValidator.Validate(RawAction: any): any?
	if type(RawAction) ~= "table" then
		return nil
	end

	local ActionId = RawAction.ActionId
	if type(ActionId) ~= "string" then
		ActionId = ""
	elseif #ActionId > 64 then
		ActionId = string.sub(ActionId, 1, 64)
	end

	local DisplayName = ValidateString(RawAction.DisplayName, 48)
	if not DisplayName then
		return nil
	end

	local Clean: { [string]: any } = {
		ActionId = ActionId,
		DisplayName = DisplayName,
		IsPlayerMade = true,
	}

	if IsGraphFormat(RawAction) then
		if type(RawAction.Branches) ~= "table" then
			return nil
		end

		Clean.Branches = {}
		local BranchCount = 0
		local HasEntry = false

		for BranchName, BranchData in RawAction.Branches do
			if BranchCount >= MAX_BRANCHES then
				break
			end

			local ValidName = ValidateString(BranchName, 32)
			if ValidName then
				local ValidBranch = ValidateGraphBranch(BranchData)
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

	elseif RawAction.Timeline then
		local Timeline = ValidateTimeline(RawAction.Timeline)
		if not Timeline or #Timeline == 0 then
			return nil
		end
		Clean.Timeline = Timeline

	elseif RawAction.Branches then
		if type(RawAction.Branches) ~= "table" then
			return nil
		end

		Clean.Branches = {}
		local BranchCount = 0
		local HasEntry = false

		for BranchName, BranchData in RawAction.Branches do
			if BranchCount >= MAX_BRANCHES then
				break
			end

			local ValidName = ValidateString(BranchName, 32)
			if ValidName then
				local ValidBranch = ValidateLegacyBranch(BranchData)
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

	if RawAction.Conditions and type(RawAction.Conditions) == "table" then
		Clean.Conditions = {
			OnAir = if type(RawAction.Conditions.OnAir) == "boolean"
				then RawAction.Conditions.OnAir
				else nil,
		}
	end

	Clean.Properties = {
		DamageMultiplier = 1,
		KnockbackMultiplier = 1,
	}

	Clean.EditorData = ValidateEditorData(RawAction.EditorData)

	return Clean
end

function ActionValidator.ValidateBlock(Block: any): any?
	return ValidateBlock(Block)
end

function ActionValidator.GetBlockDefinition(BlockType: string): BlockDefinition?
	return BlockDefinitions.Get(BlockType)
end

function ActionValidator.GetAllBlockDefinitions(): { [string]: BlockDefinition }
	return BlockDefinitions.GetAll()
end

function ActionValidator.GetSignalOutputs(BlockType: string): { PortDefintion }
	return BlockDefinitions.GetSignalOutputs(BlockType)
end

return ActionValidator