--!strict

local HttpService = game:GetService("HttpService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Canvas = require(script.Parent.Parent.Graph.Canvas)
local Node = require(script.Parent.Parent.Graph.Node)
local Wire = require(script.Parent.Parent.Graph.Wire)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)
local Toolbar = require(script.Parent.Toolbar)
local NodePalette = require(script.Parent.NodePalette)
local PropertyPanel = require(script.Parent.PropertyPanel)
local BranchList = require(script.Parent.BranchList)

local EditorWindow = {}

export type EditorWindowConfig = {
	Parent: GuiObject,
	OnSave: ((SkillData: any) -> ())?,
	OnTest: ((SkillData: any) -> ())?,
	OnLoad: (() -> ())?,
}

export type EditorWindowInstance = {
	Frame: Frame,
	LoadSkill: (SkillData: any) -> (),
	NewSkill: () -> (),
	GetSkillData: () -> any,
	SetVisible: (Visible: boolean) -> (),
	Destroy: () -> (),
}

function EditorWindow.Create(Config: EditorWindowConfig): EditorWindowInstance
	local State: Types.EditorState = {
		SkillId = "",
		DisplayName = "New Skill",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	local NodeInstances: { [string]: Node.NodeInstance } = {}
	local WireInstances: { [string]: Wire.WireInstance } = {}
	local ConnectionState: {
		IsConnecting: boolean,
		FromNodeId: string?,
		FromPortName: string?,
		FromPortType: Types.PortType?,
		FromDirection: Types.PortDirection?,
		PreviewWire: Wire.WireInstance?,
	} = {
		IsConnecting = false,
	}

	local Container = Instance.new("Frame")
	Container.Name = "SkillEditor"
	Container.Size = UDim2.fromScale(1, 1)
	Container.BackgroundColor3 = Theme.Colors.Background
	Container.BorderSizePixel = 0
	Container.Parent = Config.Parent

	local ToolbarPanel: Toolbar.ToolbarInstance = nil :: any
	local PalettePanel: NodePalette.NodePaletteInstance = nil :: any
	local PropertiesPanel: PropertyPanel.PropertyPanelInstance = nil :: any
	local BranchListPanel: BranchList.BranchListInstance = nil :: any
	local CanvasInstance: Canvas.CanvasInstance = nil :: any

	local function MarkDirty()
		State.IsDirty = true
		if ToolbarPanel then
			ToolbarPanel.SetDirty(true)
		end
	end

	local function GetCurrentBranch(): Types.BranchData?
		if not State.SelectedBranchId then
			return nil
		end
		return State.Branches[State.SelectedBranchId]
	end

	local function GetNodeData(NodeId: string): Types.NodeInstance?
		local Branch = GetCurrentBranch()
		if not Branch then
			return nil
		end
		for _, NodeData in Branch.Nodes do
			if NodeData.NodeId == NodeId then
				return NodeData
			end
		end
		return nil
	end

	local function UpdateWirePositions()
		for WireId, WireInstance in WireInstances do
			local WireData: Types.WireInstance? = nil
			local Branch = GetCurrentBranch()
			if Branch then
				for _, WireEntry in Branch.Wires do
					if WireEntry.WireId == WireId then
						WireData = WireEntry
						break
					end
				end
			end

			if WireData then
				local FromNode = NodeInstances[WireData.FromNodeId]
				local ToNode = NodeInstances[WireData.ToNodeId]

				if FromNode and ToNode then
					local FromPort = FromNode.GetPort(WireData.FromPortName)
					local ToPort = ToNode.GetPort(WireData.ToPortName)

					if FromPort and ToPort then
						WireInstance.SetPositions(FromPort.GetWorldPosition(), ToPort.GetWorldPosition())
					end
				end
			end
		end
	end

	local function SelectNode(NodeId: string?)
		if State.SelectedNodeId and NodeInstances[State.SelectedNodeId] then
			NodeInstances[State.SelectedNodeId].SetSelected(false)
		end

		State.SelectedNodeId = NodeId

		if NodeId and NodeInstances[NodeId] then
			NodeInstances[NodeId].SetSelected(true)
			local NodeData = GetNodeData(NodeId)
			PropertiesPanel.SetNode(NodeData)
		else
			PropertiesPanel.SetNode(nil)
		end
	end

	local function CreateNodeUI(NodeData: Types.NodeInstance)
		local NodeUI = NodeFactory.CreateFromBlock(NodeData, {
			Parent = CanvasInstance.Content,
			OnSelected = function(NodeId: string)
				SelectNode(NodeId)
			end,
			OnMoved = function(_NodeId: string, Position: Vector2)
				NodeData.Position = Position
				UpdateWirePositions()
				MarkDirty()
			end,
			OnPortConnectionStart = function(NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection)
				ConnectionState.IsConnecting = true
				ConnectionState.FromNodeId = NodeId
				ConnectionState.FromPortName = PortName
				ConnectionState.FromPortType = PortType
				ConnectionState.FromDirection = Direction
				ConnectionState.PreviewWire = Wire.CreatePreview(CanvasInstance.Content, PortType)
			end,
			OnPortConnectionEnd = function(NodeId: string, PortName: string)
				if not ConnectionState.IsConnecting then
					return
				end
				if ConnectionState.FromNodeId == NodeId then
					return
				end

				local Branch = GetCurrentBranch()
				if not Branch then
					return
				end

				local FromDirection = ConnectionState.FromDirection
				local _ToDirection: Types.PortDirection = if FromDirection == "Output" then "Input" else "Output"

				local FromNodeId = ConnectionState.FromNodeId :: string
				local FromPortName = ConnectionState.FromPortName :: string
				local ToNodeId = NodeId
				local ToPortName = PortName

				if FromDirection == "Input" then
					FromNodeId, ToNodeId = ToNodeId, FromNodeId
					FromPortName, ToPortName = ToPortName, FromPortName
				end

				local WireData: Types.WireInstance = {
					WireId = HttpService:GenerateGUID(false),
					FromNodeId = FromNodeId,
					FromPortName = FromPortName,
					ToNodeId = ToNodeId,
					ToPortName = ToPortName,
					WireType = ConnectionState.FromPortType :: Types.PortType,
				}

				table.insert(Branch.Wires, WireData)

				local WireUI = Wire.Create({
					WireId = WireData.WireId,
					WireType = WireData.WireType,
					Parent = CanvasInstance.Content,
				})
				WireInstances[WireData.WireId] = WireUI

				if ConnectionState.PreviewWire then
					ConnectionState.PreviewWire.Destroy()
				end

				ConnectionState.IsConnecting = false
				ConnectionState.FromNodeId = nil
				ConnectionState.FromPortName = nil
				ConnectionState.FromPortType = nil
				ConnectionState.FromDirection = nil
				ConnectionState.PreviewWire = nil

				UpdateWirePositions()
				MarkDirty()
			end,
		})

		if NodeUI then
			NodeInstances[NodeData.NodeId] = NodeUI
		end
	end

	local function ClearCanvas()
		for _, NodeUI in NodeInstances do
			NodeUI.Destroy()
		end
		table.clear(NodeInstances)

		for _, WireUI in WireInstances do
			WireUI.Destroy()
		end
		table.clear(WireInstances)

		SelectNode(nil)
	end

	local function RenderBranch(BranchId: string)
		ClearCanvas()

		local Branch = State.Branches[BranchId]
		if not Branch then
			return
		end

		for _, NodeData in Branch.Nodes do
			CreateNodeUI(NodeData)
		end

		for _, WireData in Branch.Wires do
			local WireUI = Wire.Create({
				WireId = WireData.WireId,
				WireType = WireData.WireType,
				Parent = CanvasInstance.Content,
			})
			WireInstances[WireData.WireId] = WireUI
		end

		task.defer(UpdateWirePositions)
	end

	local function SelectBranch(BranchId: string)
		State.SelectedBranchId = BranchId
		BranchListPanel.SetSelectedBranch(BranchId)
		RenderBranch(BranchId)
	end

	local function CreateBranch(BranchName: string): string
		local BranchId = HttpService:GenerateGUID(false)
		local IsEntry = next(State.Branches) == nil

		local BranchData: Types.BranchData = {
			BranchId = BranchId,
			BranchName = BranchName,
			IsEntry = IsEntry,
			Nodes = {},
			Wires = {},
			Position = Vector2.zero,
			Collapsed = false,
		}

		State.Branches[BranchId] = BranchData
		BranchListPanel.SetBranches(State.Branches)
		MarkDirty()

		return BranchId
	end

	local function AddNodeToBranch(BlockType: string)
		local Branch = GetCurrentBranch()
		if not Branch then
			local BranchId = CreateBranch("Main")
			SelectBranch(BranchId)
			Branch = State.Branches[BranchId]
		end
        if not Branch then return end

		local CanvasCenter = CanvasInstance.CanvasToWorld(Vector2.new(
			CanvasInstance.Frame.AbsoluteSize.X / 2,
			CanvasInstance.Frame.AbsoluteSize.Y / 2
		))

		local NodeData = NodeFactory.CreateNodeInstance(BlockType, CanvasCenter)
		table.insert(Branch.Nodes, NodeData)

		CreateNodeUI(NodeData)
		SelectNode(NodeData.NodeId)
		MarkDirty()
	end

	local function OnPropertyChanged(NodeId: string, Key: string, Value: any)
		local NodeData = GetNodeData(NodeId)
		if NodeData then
			NodeData.Properties[Key] = Value
			MarkDirty()
		end
	end

	ToolbarPanel = Toolbar.Create({
		Parent = Container,
		OnNew = function()
			State.SkillId = ""
			State.DisplayName = "New Skill"
			State.Branches = {}
			State.IsDirty = false
			ToolbarPanel.SetSkillName("New Skill")
			ToolbarPanel.SetDirty(false)
			BranchListPanel.SetBranches({})
			ClearCanvas()
		end,
		OnSave = function()
			if Config.OnSave then
				local SkillData = EditorWindow.ExportSkillData(State)
				Config.OnSave(SkillData)
			end
		end,
		OnLoad = function()
			if Config.OnLoad then
				Config.OnLoad()
			end
		end,
		OnTest = function()
			if Config.OnTest then
				local SkillData = EditorWindow.ExportSkillData(State)
				Config.OnTest(SkillData)
			end
		end,
		OnNameChanged = function(Name: string)
			State.DisplayName = Name
			MarkDirty()
		end,
	})
	ToolbarPanel.Frame.Position = UDim2.new(0, 0, 0, 0)

	local ContentArea = Instance.new("Frame")
	ContentArea.Name = "ContentArea"
	ContentArea.Size = UDim2.new(1, 0, 1, -Theme.Sizes.ToolbarHeight)
	ContentArea.Position = UDim2.fromOffset(0, Theme.Sizes.ToolbarHeight)
	ContentArea.BackgroundTransparency = 1
	ContentArea.Parent = Container

	CanvasInstance = Canvas.Create({
		Name = "Canvas",
		Size = UDim2.new(1, -(Theme.Sizes.PanelWidth * 2), 1, 0),
		Position = UDim2.fromOffset(Theme.Sizes.PanelWidth, 0),
		Parent = ContentArea,
	})

	PalettePanel = NodePalette.Create({
		Parent = ContentArea,
		OnNodeSelected = function(BlockType: string)
			AddNodeToBranch(BlockType)
		end,
	})

	PropertiesPanel = PropertyPanel.Create({
		Parent = ContentArea,
		OnPropertyChanged = OnPropertyChanged,
	})

	BranchListPanel = BranchList.Create({
		Parent = ContentArea,
		OnBranchSelected = function(BranchId: string)
			SelectBranch(BranchId)
		end,
		OnBranchCreated = function(BranchName: string)
			local BranchId = CreateBranch(BranchName)
			SelectBranch(BranchId)
		end,
	})

	local Instance: EditorWindowInstance = {
		Frame = Container,
	} :: any

	function Instance.LoadSkill(SkillData: any)
		State = EditorWindow.ImportSkillData(SkillData)
		ToolbarPanel.SetSkillName(State.DisplayName)
		ToolbarPanel.SetDirty(false)
		BranchListPanel.SetBranches(State.Branches)

		local FirstBranchId: string? = nil
		for BranchId, Branch in State.Branches do
			if Branch.IsEntry then
				FirstBranchId = BranchId
				break
			end
			if not FirstBranchId then
				FirstBranchId = BranchId
			end
		end

		if FirstBranchId then
			SelectBranch(FirstBranchId)
		end
	end

	function Instance.NewSkill()
		ToolbarPanel.Frame.Parent = nil
		ToolbarPanel = Toolbar.Create({
			Parent = Container,
			OnNew = function() Instance.NewSkill() end,
			OnSave = function()
				if Config.OnSave then
					Config.OnSave(EditorWindow.ExportSkillData(State))
				end
			end,
			OnLoad = Config.OnLoad,
			OnTest = function()
				if Config.OnTest then
					Config.OnTest(EditorWindow.ExportSkillData(State))
				end
			end,
			OnNameChanged = function(Name)
                State.DisplayName = Name
                MarkDirty()
            end,
		})
	end

	function Instance.GetSkillData(): any
		return EditorWindow.ExportSkillData(State)
	end

	function Instance.SetVisible(Visible: boolean)
		Container.Visible = Visible
	end

	function Instance.Destroy()
		ClearCanvas()
		ToolbarPanel.Destroy()
		PalettePanel.Destroy()
		PropertiesPanel.Destroy()
		BranchListPanel.Destroy()
		CanvasInstance.Destroy()
		Container:Destroy()
	end

	return Instance
end

function EditorWindow.ImportSkillData(SkillData: any): Types.EditorState
	local State: Types.EditorState = {
		SkillId = SkillData.SkillId or "",
		DisplayName = SkillData.DisplayName or "Imported Skill",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	if SkillData.Timeline then
		local BranchId = HttpService:GenerateGUID(false)
		local Nodes: { Types.NodeInstance } = {}
		local PositionX = 0

		for _, Block in SkillData.Timeline do
			local NodeData = NodeFactory.BlockToNode(Block, Vector2.new(PositionX, 0))
			table.insert(Nodes, NodeData)
			PositionX = PositionX + Theme.Sizes.NodeWidth + 40
		end

		State.Branches[BranchId] = {
			BranchId = BranchId,
			BranchName = "Main",
			IsEntry = true,
			Nodes = Nodes,
			Wires = {},
			Position = Vector2.zero,
		}
	elseif SkillData.Branches then
		for BranchName, BranchData in SkillData.Branches do
			local BranchId = HttpService:GenerateGUID(false)
			local Nodes: { Types.NodeInstance } = {}
			local PositionX = 0

			if BranchData.Timeline then
				for _, Block in BranchData.Timeline do
					local NodeData = NodeFactory.BlockToNode(Block, Vector2.new(PositionX, 0))
					table.insert(Nodes, NodeData)
					PositionX = PositionX + Theme.Sizes.NodeWidth + 40
				end
			end

			State.Branches[BranchId] = {
				BranchId = BranchId,
				BranchName = BranchName,
				IsEntry = BranchData.Entry == true,
				Nodes = Nodes,
				Wires = {},
				Position = Vector2.zero,
			}
		end
	end

	return State
end

function EditorWindow.ExportSkillData(State: Types.EditorState): any
	local SkillData: any = {
		SkillId = State.SkillId,
		DisplayName = State.DisplayName,
		IsPlayerMade = true,
	}

	local BranchCount = 0
	for _ in State.Branches do
		BranchCount = BranchCount + 1
	end

	if BranchCount == 1 then
		for _, Branch in State.Branches do
			if Branch.IsEntry then
				local Timeline = {}
				for _, NodeData in Branch.Nodes do
					local Block = NodeFactory.NodeToBlock(NodeData)
					table.insert(Timeline, Block)
				end
				SkillData.Timeline = Timeline
				break
			end
		end
	else
		SkillData.Branches = {}
		for _, Branch in State.Branches do
			local Timeline = {}
			for _, NodeData in Branch.Nodes do
				local Block = NodeFactory.NodeToBlock(NodeData)
				table.insert(Timeline, Block)
			end
			SkillData.Branches[Branch.BranchName] = {
				Entry = Branch.IsEntry,
				Timeline = Timeline,
			}
		end
	end

	return SkillData
end

return EditorWindow