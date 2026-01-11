--!strict

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Canvas = require(script.Parent.Parent.Graph.Canvas)
local Node = require(script.Parent.Parent.Graph.Node)
local Wire = require(script.Parent.Parent.Graph.Wire)
local Comment = require(script.Parent.Parent.Graph.Comment)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)
local NodeRegistry = require(script.Parent.Parent.Nodes.NodeRegistry)
local Toolbar = require(script.Parent.Toolbar)
local NodePalette = require(script.Parent.NodePalette)
local PropertyPanel = require(script.Parent.PropertyPanel)
local BranchList = require(script.Parent.BranchList)
local Modal = require(script.Parent.Parent.Components.Modal)
local Notification = require(script.Parent.Parent.Components.Notification)

local EditorWindow = {}

export type EditorWindowConfig = {
	Parent: GuiObject,
	OnSave: ((SkillData: any) -> boolean?)?,
	OnTest: ((SkillData: any) -> ())?,
	OnLoad: ((SkillId: string) -> any?)?,
	GetSkillsList: (() -> { { Id: string, Name: string } })?,
}

export type EditorWindowInstance = {
	Frame: Frame,
	LoadSkill: (SkillData: any) -> (),
	NewSkill: () -> (),
	GetSkillData: () -> any,
	SetSkillId: (NewSkillId: string) -> (),
	GetSkillId: () -> string,
	SetVisible: (Visible: boolean) -> (),
	Destroy: () -> (),
}

local NODE_SPAWN_OFFSET = 40

function EditorWindow.Create(Config: EditorWindowConfig): EditorWindowInstance
	local State: Types.EditorState = {
		SkillId = "",
		DisplayName = "New Skill",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		SelectedCommentId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	local NodeInstances: { [string]: Node.NodeInstance } = {}
	local WireInstances: { [string]: Wire.WireInstance } = {}
	local CommentInstances: { [string]: Comment.CommentInstance } = {}
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

	local SpawnCounter = 0

	local EditorInstance: EditorWindowInstance = nil :: any

	local Container = Instance.new("Frame")
	Container.Name = "SkillEditor"
	Container.Size = UDim2.fromScale(1, 1)
	Container.BackgroundColor3 = Theme.Colors.Background
	Container.BorderSizePixel = 0
	Container.Parent = Config.Parent

	local ModalBackground = Instance.new("TextButton")
	ModalBackground.Name = "ModalBackground"
	ModalBackground.Size = UDim2.fromScale(1, 1)
	ModalBackground.BackgroundTransparency = 1
	ModalBackground.Text = ""
	ModalBackground.ZIndex = 0
	ModalBackground.Modal = true
	ModalBackground.Parent = Container

	local ToolbarPanel: Toolbar.ToolbarInstance = nil :: any
	local PalettePanel: NodePalette.NodePaletteInstance = nil :: any
	local PropertiesPanel: PropertyPanel.PropertyPanelInstance = nil :: any
	local BranchListPanel: BranchList.BranchListInstance = nil :: any
	local CanvasInstance: Canvas.CanvasInstance = nil :: any

	local EditorConnections: { RBXScriptConnection } = {}

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
		local Branch = GetCurrentBranch()
		if not Branch then
			return
		end

		task.defer(function()
			for WireId, WireInstance in WireInstances do
				local WireData: Types.WireInstance? = nil
				for _, WireItem in Branch.Wires do
					if WireItem.WireId == WireId then
						WireData = WireItem
						break
					end
				end

				if not WireData then
					continue
				end

				local FromNode = NodeInstances[WireData.FromNodeId]
				local ToNode = NodeInstances[WireData.ToNodeId]

				if not FromNode or not ToNode then
					continue
				end

				local FromPort = FromNode.GetPort(WireData.FromPortName)
				local ToPort = ToNode.GetPort(WireData.ToPortName)

				if not FromPort or not ToPort then
					continue
				end

				local StartPos = FromPort.GetWorldPosition()
				local EndPos = ToPort.GetWorldPosition()

				WireInstance.SetPositions(StartPos, EndPos)
			end
		end)
	end

	local function UpdatePreviewWire()
		if not ConnectionState.IsConnecting or not ConnectionState.PreviewWire then
			return
		end

		local FromNodeId = ConnectionState.FromNodeId
		local FromPortName = ConnectionState.FromPortName
		if not FromNodeId or not FromPortName then
			return
		end

		local FromNode = NodeInstances[FromNodeId]
		if not FromNode then
			return
		end

		local FromPort = FromNode.GetPort(FromPortName)
		if not FromPort then
			return
		end

		local StartPos = FromPort.GetWorldPosition()
		local MousePosition = UserInputService:GetMouseLocation()
		local GuiInset = GuiService:GetGuiInset()
		MousePosition = MousePosition - GuiInset

		ConnectionState.PreviewWire.SetPositions(StartPos, MousePosition)
	end

	local function CancelConnection()
		if ConnectionState.PreviewWire then
			ConnectionState.PreviewWire.Destroy()
		end
		ConnectionState.IsConnecting = false
		ConnectionState.FromNodeId = nil
		ConnectionState.FromPortName = nil
		ConnectionState.FromPortType = nil
		ConnectionState.FromDirection = nil
		ConnectionState.PreviewWire = nil
	end

	local function SelectComment(CommentId: string?)
		if State.SelectedCommentId and CommentInstances[State.SelectedCommentId] then
			CommentInstances[State.SelectedCommentId].SetSelected(false)
		end

		State.SelectedCommentId = CommentId

		if CommentId and CommentInstances[CommentId] then
			CommentInstances[CommentId].SetSelected(true)
		end
	end

	local function SelectNode(NodeId: string?)
		if State.SelectedCommentId and CommentInstances[State.SelectedCommentId] then
			CommentInstances[State.SelectedCommentId].SetSelected(false)
			State.SelectedCommentId = nil
		end

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

	local function DeleteWire(WireId: string)
		local Branch = GetCurrentBranch()
		if not Branch then
			return
		end

		local WireUI = WireInstances[WireId]
		if WireUI then
			WireUI.Destroy()
			WireInstances[WireId] = nil
		end

		for Index, WireData in Branch.Wires do
			if WireData.WireId == WireId then
				table.remove(Branch.Wires, Index)
				break
			end
		end

		MarkDirty()
	end

	local function DeleteNode(NodeId: string)
		local Branch = GetCurrentBranch()
		if not Branch then
			return
		end

		local WiresToRemove: { string } = {}
		for _, WireData in Branch.Wires do
			if WireData.FromNodeId == NodeId or WireData.ToNodeId == NodeId then
				table.insert(WiresToRemove, WireData.WireId)
			end
		end

		for _, WireId in WiresToRemove do
			local WireUI = WireInstances[WireId]
			if WireUI then
				WireUI.Destroy()
				WireInstances[WireId] = nil
			end

			for Index, WireData in Branch.Wires do
				if WireData.WireId == WireId then
					table.remove(Branch.Wires, Index)
					break
				end
			end
		end

		local NodeUI = NodeInstances[NodeId]
		if NodeUI then
			NodeUI.Destroy()
			NodeInstances[NodeId] = nil
		end

		for Index, NodeData in Branch.Nodes do
			if NodeData.NodeId == NodeId then
				table.remove(Branch.Nodes, Index)
				break
			end
		end

		if State.SelectedNodeId == NodeId then
			State.SelectedNodeId = nil
			PropertiesPanel.SetNode(nil)
		end

		MarkDirty()
	end

	local function DeleteComment(CommentId: string)
		local Branch = GetCurrentBranch()
		if not Branch or not Branch.Comments then
			return
		end

		local CommentUI = CommentInstances[CommentId]
		if CommentUI then
			CommentUI.Destroy()
			CommentInstances[CommentId] = nil
		end

		for Index, CommentData in Branch.Comments do
			if CommentData.CommentId == CommentId then
				table.remove(Branch.Comments, Index)
				break
			end
		end

		if State.SelectedCommentId == CommentId then
			State.SelectedCommentId = nil
		end

		MarkDirty()
	end

	local function CreateCommentUI(CommentData: Types.CommentData)
		local CommentUI = Comment.Create({
			CommentId = CommentData.CommentId,
			Title = CommentData.Title,
			Text = CommentData.Text,
			Color = CommentData.Color,
			Position = CommentData.Position,
			Size = CommentData.Size,
			Parent = CanvasInstance.Content,
			OnSelected = function(CommentId: string)
				SelectNode(nil)
				SelectComment(CommentId)
			end,
			OnMoved = function(_CommentId: string, Position: Vector2)
				CommentData.Position = Position
				MarkDirty()
			end,
			OnResized = function(_CommentId: string, Size: Vector2)
				CommentData.Size = Size
				MarkDirty()
			end,
			OnTitleChanged = function(_CommentId: string, Title: string)
				CommentData.Title = Title
				MarkDirty()
			end,
			OnTextChanged = function(_CommentId: string, Text: string)
				CommentData.Text = Text
				MarkDirty()
			end,
		})

		CommentInstances[CommentData.CommentId] = CommentUI
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
				UpdatePreviewWire()
			end,
			OnPortConnectionEnd = function(NodeId: string, PortName: string)
				if not ConnectionState.IsConnecting then
					return
				end
				if ConnectionState.FromNodeId == NodeId then
					CancelConnection()
					return
				end

				local Branch = GetCurrentBranch()
				if not Branch then
					CancelConnection()
					return
				end

				local ToNodeData = GetNodeData(NodeId)
				if not ToNodeData then
					CancelConnection()
					return
				end

				local ToPortDirection: Types.PortDirection? = nil
				local ToPortType: Types.PortType? = nil
				local ToDefinition = NodeRegistry.Get(ToNodeData.BlockType)
				if ToDefinition then
					for _, PortDef in ToDefinition.Ports do
						if PortDef.Name == PortName then
							ToPortDirection = PortDef.Direction
							ToPortType = PortDef.PortType
							break
						end
					end
				end

				if not ToPortDirection then
					CancelConnection()
					return
				end

				local FromDirection = ConnectionState.FromDirection
				if FromDirection == ToPortDirection then
					CancelConnection()
					return
				end

				local FromPortType = ConnectionState.FromPortType
				if FromPortType ~= ToPortType then
					CancelConnection()
					return
				end

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
					OnClick = function(ClickedWireId: string)
						DeleteWire(ClickedWireId)
					end,
					CanInteract = function()
						return not ConnectionState.IsConnecting
					end,
				})
				WireInstances[WireData.WireId] = WireUI

				CancelConnection()
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

		for _, CommentUI in CommentInstances do
			CommentUI.Destroy()
		end
		table.clear(CommentInstances)

		SelectNode(nil)
		SelectComment(nil)
		SpawnCounter = 0
	end

	local function RenderBranch(BranchId: string)
		ClearCanvas()

		local Branch = State.Branches[BranchId]
		if not Branch then
			return
		end

		if Branch.Comments then
			for _, CommentData in Branch.Comments do
				CreateCommentUI(CommentData)
			end
		end

		for _, NodeData in Branch.Nodes do
			CreateNodeUI(NodeData)
		end

		for _, WireData in Branch.Wires do
			local WireUI = Wire.Create({
				WireId = WireData.WireId,
				WireType = WireData.WireType,
				Parent = CanvasInstance.Content,
				OnClick = function(ClickedWireId: string)
					DeleteWire(ClickedWireId)
				end,
				CanInteract = function()
					return not ConnectionState.IsConnecting
				end,
			})
			WireInstances[WireData.WireId] = WireUI
		end

		UpdateWirePositions()
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
			Comments = {},
			Position = Vector2.zero,
			Collapsed = false,
		}

		State.Branches[BranchId] = BranchData
		BranchListPanel.SetBranches(State.Branches)
		MarkDirty()

		return BranchId
	end

	local function DeleteBranch(BranchId: string)
		if not State.Branches[BranchId] then
			return
		end

		if State.SelectedBranchId == BranchId then
			ClearCanvas()
			State.SelectedBranchId = nil
		end

		State.Branches[BranchId] = nil
		BranchListPanel.SetBranches(State.Branches)

		local FirstBranchId: string? = nil
		for Id in State.Branches do
			FirstBranchId = Id
			break
		end

		if FirstBranchId then
			SelectBranch(FirstBranchId)
		end

		MarkDirty()
	end

	local function GetSpawnPosition(): Vector2
		local CanvasCenter = CanvasInstance.CanvasToWorld(Vector2.new(
			CanvasInstance.Frame.AbsoluteSize.X / 2,
			CanvasInstance.Frame.AbsoluteSize.Y / 2
		))

		local OffsetX = (SpawnCounter % 5) * (Theme.Sizes.NodeWidth + NODE_SPAWN_OFFSET)
		local OffsetY = math.floor(SpawnCounter / 5) * 100

		SpawnCounter = SpawnCounter + 1

		return CanvasCenter + Vector2.new(OffsetX - 200, OffsetY - 100)
	end

	local function AddComment()
		local Branch = GetCurrentBranch()
		if not Branch then
			local BranchId = CreateBranch("Main")
			SelectBranch(BranchId)
			Branch = State.Branches[BranchId]
		end
		if not Branch then
			return
		end

		local Comments = Branch.Comments or {}

		local SpawnPosition = GetSpawnPosition()

		local CommentData: Types.CommentData = {
			CommentId = HttpService:GenerateGUID(false),
			Title = "Comment",
			Text = "",
			Color = Comment.DefaultColor,
			Position = SpawnPosition,
			Size = Vector2.new(300, 150),
		}

		table.insert(Comments, CommentData)
		CreateCommentUI(CommentData)
		SelectNode(nil)
		SelectComment(CommentData.CommentId)
		MarkDirty()
	end

	local function AddNodeToBranch(BlockType: string)
		if BlockType == "Comment" then
			AddComment()
			return
		end

		local Branch = GetCurrentBranch()
		if not Branch then
			local BranchId = CreateBranch("Main")
			SelectBranch(BranchId)
			Branch = State.Branches[BranchId]
		end
		if not Branch then
			return
		end

		local SpawnPosition = GetSpawnPosition()
		local NodeData = NodeFactory.CreateNodeInstance(BlockType, SpawnPosition)
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

	local function OnNodeDelete(NodeId: string)
		DeleteNode(NodeId)
	end

	table.insert(EditorConnections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			UpdatePreviewWire()
		end
	end))

	table.insert(EditorConnections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ConnectionState.IsConnecting then
				CancelConnection()
			end
		end
	end))

	table.insert(EditorConnections, UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Delete or Input.KeyCode == Enum.KeyCode.Backspace then
			if State.SelectedCommentId then
				DeleteComment(State.SelectedCommentId)
			elseif State.SelectedNodeId then
				DeleteNode(State.SelectedNodeId)
			end
		end
	end))

	local function ResetToNewSkill()
		State.SkillId = ""
		State.DisplayName = "New Skill"
		State.Branches = {}
		State.IsDirty = false
		State.SelectedCommentId = nil
		ToolbarPanel.SetSkillName("New Skill")
		ToolbarPanel.SetDirty(false)
		BranchListPanel.SetBranches({})
		ClearCanvas()
	end

	ToolbarPanel = Toolbar.Create({
		Parent = Container,
		OnNew = function()
			if State.IsDirty then
				Modal.Confirm({
					Title = "Unsaved Changes",
					Message = "You have unsaved changes. Are you sure you want to create a new skill?",
					ConfirmText = "Discard",
					ConfirmColor = Theme.Colors.Error,
					Parent = Container,
					OnConfirm = function()
						ResetToNewSkill()
					end,
				})
			else
				ResetToNewSkill()
			end
		end,
		OnSave = function()
			if Config.OnSave then
				local SkillData = EditorWindow.ExportSkillData(State)
				local Success = Config.OnSave(SkillData)
				if Success ~= false then
					State.IsDirty = false
					ToolbarPanel.SetDirty(false)
					Notification.Success("Skill saved successfully!", Container)
				else
					Notification.Error("Failed to save skill.", Container)
				end
			end
		end,
		OnLoad = function()
			local function ShowLoadModal()
				local SkillsList = if Config.GetSkillsList then Config.GetSkillsList() else {}

				Modal.Select({
					Title = "Load Skill",
					Options = SkillsList,
					Parent = Container,
					OnSelected = function(SkillId: string)
						if Config.OnLoad then
							local LoadedData = Config.OnLoad(SkillId)
							if LoadedData then
								EditorInstance.LoadSkill(LoadedData)
								Notification.Success("Skill loaded!", Container)
							else
								Notification.Error("Failed to load skill.", Container)
							end
						end
					end,
				})
			end

			if State.IsDirty then
				Modal.Confirm({
					Title = "Unsaved Changes",
					Message = "You have unsaved changes. Are you sure you want to load a different skill?",
					ConfirmText = "Discard",
					ConfirmColor = Theme.Colors.Error,
					Parent = Container,
					OnConfirm = function()
						ShowLoadModal()
					end,
				})
			else
				ShowLoadModal()
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
		GridImage = if Theme.Assets.GridImage ~= "" then Theme.Assets.GridImage else nil,
		Parent = ContentArea,
		OnBackgroundClick = function()
			SelectNode(nil)
			SelectComment(nil)
			CancelConnection()
		end,
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
		OnNodeDelete = OnNodeDelete,
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
		OnBranchDeleted = function(BranchId: string)
			DeleteBranch(BranchId)
		end,
		OnBranchRenamed = function(BranchId: string, NewName: string)
			local Branch = State.Branches[BranchId]
			if Branch then
				Branch.BranchName = NewName
				MarkDirty()
			end
		end,
	})

	EditorInstance = {
		Frame = Container,
	} :: any

	function EditorInstance.LoadSkill(SkillData: any)
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

	function EditorInstance.NewSkill()
		State.SkillId = ""
		State.DisplayName = "New Skill"
		State.Branches = {}
		State.IsDirty = false
		State.SelectedCommentId = nil
		ToolbarPanel.SetSkillName("New Skill")
		ToolbarPanel.SetDirty(false)
		BranchListPanel.SetBranches({})
		ClearCanvas()
	end

	function EditorInstance.GetSkillData(): any
		return EditorWindow.ExportSkillData(State)
	end

	function EditorInstance.SetSkillId(NewSkillId: string)
		State.SkillId = NewSkillId
	end

	function EditorInstance.GetSkillId(): string
		return State.SkillId
	end

	function EditorInstance.SetVisible(Visible: boolean)
		Container.Visible = Visible
	end

	function EditorInstance.Destroy()
		for _, Connection in EditorConnections do
			Connection:Disconnect()
		end
		table.clear(EditorConnections)

		ClearCanvas()
		ToolbarPanel.Destroy()
		PalettePanel.Destroy()
		PropertiesPanel.Destroy()
		BranchListPanel.Destroy()
		CanvasInstance.Destroy()
		Container:Destroy()
	end

	return EditorInstance
end

local function SerializeWires(Wires: { Types.WireInstance }): { any }
	local SerializedWires = {}
	for _, WireData in Wires do
		table.insert(SerializedWires, {
			WireId = WireData.WireId,
			FromNodeId = WireData.FromNodeId,
			FromPortName = WireData.FromPortName,
			ToNodeId = WireData.ToNodeId,
			ToPortName = WireData.ToPortName,
			WireType = WireData.WireType,
		})
	end
	return SerializedWires
end

local function DeserializeWires(SerializedWires: { any }?): { Types.WireInstance }
	if not SerializedWires then
		return {}
	end

	local Wires: { Types.WireInstance } = {}
	for _, WireData in SerializedWires do
		table.insert(Wires, {
			WireId = WireData.WireId or HttpService:GenerateGUID(false),
			FromNodeId = WireData.FromNodeId,
			FromPortName = WireData.FromPortName,
			ToNodeId = WireData.ToNodeId,
			ToPortName = WireData.ToPortName,
			WireType = WireData.WireType or "Flow",
		})
	end
	return Wires
end

local function SerializeComments(Comments: { Types.CommentData }?): { any }?
	if not Comments or #Comments == 0 then
		return nil
	end

	local SerializedComments = {}
	for _, CommentData in Comments do
		table.insert(SerializedComments, {
			CommentId = CommentData.CommentId,
			Title = CommentData.Title,
			Text = CommentData.Text,
			Color = {
				R = CommentData.Color.R,
				G = CommentData.Color.G,
				B = CommentData.Color.B,
			},
			Position = {
				X = CommentData.Position.X,
				Y = CommentData.Position.Y,
			},
			Size = {
				X = CommentData.Size.X,
				Y = CommentData.Size.Y,
			},
		})
	end
	return SerializedComments
end

local function DeserializeComments(SerializedComments: { any }?): { Types.CommentData }
	if not SerializedComments then
		return {}
	end

	local Comments: { Types.CommentData } = {}
	for _, Data in SerializedComments do
		local Color = Comment.DefaultColor
		if Data.Color then
			Color = Color3.new(Data.Color.R or 0, Data.Color.G or 0, Data.Color.B or 0)
		end

		local Position = Vector2.zero
		if Data.Position then
			Position = Vector2.new(Data.Position.X or 0, Data.Position.Y or 0)
		end

		local Size = Vector2.new(300, 150)
		if Data.Size then
			Size = Vector2.new(Data.Size.X or 300, Data.Size.Y or 150)
		end

		table.insert(Comments, {
			CommentId = Data.CommentId or HttpService:GenerateGUID(false),
			Title = Data.Title or "Comment",
			Text = Data.Text or "",
			Color = Color,
			Position = Position,
			Size = Size,
		})
	end
	return Comments
end

function EditorWindow.ImportSkillData(SkillData: any): Types.EditorState
	local State: Types.EditorState = {
		SkillId = SkillData.SkillId or "",
		DisplayName = SkillData.DisplayName or "Imported Skill",
		Branches = {},
		SelectedNodeId = nil,
		SelectedBranchId = nil,
		SelectedWireId = nil,
		SelectedCommentId = nil,
		CanvasOffset = Vector2.zero,
		CanvasZoom = 1,
		IsDirty = false,
	}

	local EditorData = SkillData.EditorData or {}
	local EditorWires = EditorData.Wires or {}
	local EditorComments = EditorData.Comments or {}

	if SkillData.Timeline then
		local BranchId = HttpService:GenerateGUID(false)
		local Nodes: { Types.NodeInstance } = {}
		local FallbackPositionX = 0

		for _, Block in SkillData.Timeline do
			local FallbackPosition = Vector2.new(FallbackPositionX, 0)
			local NodeData = NodeFactory.BlockToNode(Block, FallbackPosition)
			table.insert(Nodes, NodeData)
			FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40
		end

		local BranchWires = DeserializeWires(EditorWires["Main"] or EditorWires[1])
		local BranchComments = DeserializeComments(EditorComments["Main"])

		State.Branches[BranchId] = {
			BranchId = BranchId,
			BranchName = "Main",
			IsEntry = true,
			Nodes = Nodes,
			Wires = BranchWires,
			Comments = BranchComments,
			Position = Vector2.zero,
		}
	elseif SkillData.Branches then
		for BranchName, BranchData in SkillData.Branches do
			local BranchId = HttpService:GenerateGUID(false)
			local Nodes: { Types.NodeInstance } = {}
			local FallbackPositionX = 0

			if BranchData.Timeline then
				for _, Block in BranchData.Timeline do
					local FallbackPosition = Vector2.new(FallbackPositionX, 0)
					local NodeData = NodeFactory.BlockToNode(Block, FallbackPosition)
					table.insert(Nodes, NodeData)
					FallbackPositionX = FallbackPositionX + Theme.Sizes.NodeWidth + 40
				end
			end

			local BranchWires = DeserializeWires(EditorWires[BranchName])
			local BranchComments = DeserializeComments(EditorComments[BranchName])

			State.Branches[BranchId] = {
				BranchId = BranchId,
				BranchName = BranchName,
				IsEntry = BranchData.Entry == true,
				Nodes = Nodes,
				Wires = BranchWires,
				Comments = BranchComments,
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

	local EditorWires: { [string]: any } = {}
	local EditorComments: { [string]: any } = {}

	if BranchCount == 1 then
		for _, Branch in State.Branches do
			if Branch.IsEntry then
				local Timeline = {}
				for _, NodeData in Branch.Nodes do
					local Block = NodeFactory.NodeToBlock(NodeData)
					table.insert(Timeline, Block)
				end
				SkillData.Timeline = Timeline
				EditorWires["Main"] = SerializeWires(Branch.Wires)
				EditorComments["Main"] = SerializeComments(Branch.Comments)
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
			EditorWires[Branch.BranchName] = SerializeWires(Branch.Wires)
			EditorComments[Branch.BranchName] = SerializeComments(Branch.Comments)
		end
	end

	SkillData.EditorData = {
		Wires = EditorWires,
		Comments = EditorComments,
	}

	return SkillData
end

return EditorWindow