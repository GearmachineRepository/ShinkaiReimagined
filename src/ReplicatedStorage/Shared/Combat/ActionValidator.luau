--!strict

local BlockDefinitions = require(script.Parent.BlockDefinitions)

local ActionValidator = {}

type BlockDefinition = BlockDefinitions.BlockDefinition
type PortDefintion = BlockDefinitions.PortDefinition

local MAX_BLOCKS = 50
local MAX_BRANCHES = 10
local MAX_SIGNAL_LENGTH = 32
local MAX_ID_LENGTH = 64
local MAX_COMMENTS = 50
local MAX_WIRES = 200

local ALLOWED_BLOCK_TYPES: { [string]: boolean } = {}

for BlockType, _ in BlockDefinitions.GetAll() do
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
	local Definition = BlockDefinitions.Get(BlockType)
	if not Definition then
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

	for _, PropDef in Definition.Properties do
		local Key = PropDef.Key
		local Value = Block[Key]

		if PropDef.Type == "Number" then
			local Min = PropDef.Min or -9999
			local Max = PropDef.Max or 9999
			local Default = PropDef.Default or 0
			Clean[Key] = ValidateNumber(Value, Min, Max, Default)

		elseif PropDef.Type == "Boolean" then
			local Default = if PropDef.Default ~= nil then PropDef.Default else false
			Clean[Key] = ValidateBoolean(Value, Default)

		elseif PropDef.Type == "String" or PropDef.Type == "AssetId" then
			local Default = PropDef.Default or ""
			local Validated = ValidateStringAllowEmpty(Value, 256)
			Clean[Key] = if Validated ~= nil then Validated else Default

		elseif PropDef.Type == "Dropdown" or PropDef.Type == "BranchDropdown" then
			local Default = PropDef.Default or ""
			if type(Value) == "string" then
				local Validated = ValidateStringAllowEmpty(Value, 64)
				Clean[Key] = if Validated ~= nil then Validated else Default
			else
				Clean[Key] = Default
			end
		end
	end

	if Block.Outputs and type(Block.Outputs) == "table" then
		local ValidOutputs = {}
		for OutputName, SignalId in Block.Outputs do
			local ValidOutput = ValidateString(OutputName, 32)
			local ValidSignal = ValidateString(SignalId, MAX_SIGNAL_LENGTH)
			if ValidOutput and ValidSignal then
				ValidOutputs[ValidOutput] = ValidSignal
			end
		end
		if next(ValidOutputs) then
			Clean.Outputs = ValidOutputs
		end
	end

	return Clean
end


local function ValidateNode(NodeId: string, NodeData: any): any?
	if type(NodeData) ~= "table" then
		return nil
	end

	local BlockType = NodeData.BlockType
	local Definition = BlockDefinitions.Get(BlockType)
	if not Definition then
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

	for _, PropDef in Definition.Properties do
		local Key = PropDef.Key
		local Value = NodeData[Key]

		if PropDef.Type == "Number" then
			local Min = PropDef.Min or -9999
			local Max = PropDef.Max or 9999
			local Default = PropDef.Default or 0
			Clean[Key] = ValidateNumber(Value, Min, Max, Default)

		elseif PropDef.Type == "Boolean" then
			local Default = if PropDef.Default ~= nil then PropDef.Default else false
			Clean[Key] = ValidateBoolean(Value, Default)

		elseif PropDef.Type == "String" or PropDef.Type == "AssetId" then
			local Default = PropDef.Default or ""
			local Validated = ValidateStringAllowEmpty(Value, 256)
			Clean[Key] = if Validated ~= nil then Validated else Default

		elseif PropDef.Type == "Dropdown" or PropDef.Type == "BranchDropdown" then
			local Default = PropDef.Default or ""
			if type(Value) == "string" then
				local Validated = ValidateStringAllowEmpty(Value, 64)
				Clean[Key] = if Validated ~= nil then Validated else Default
			else
				Clean[Key] = Default
			end
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