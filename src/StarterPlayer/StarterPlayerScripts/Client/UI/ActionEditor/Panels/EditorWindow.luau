--!strict

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Canvas = require(script.Parent.Parent.Graph.Canvas)
local Node = require(script.Parent.Parent.Graph.Node)
local Wire = require(script.Parent.Parent.Graph.Wire)
local Comment = require(script.Parent.Parent.Graph.Comment)
local NodeFactory = require(script.Parent.Parent.Nodes.NodeFactory)
local Toolbar = require(script.Parent.Toolbar)
local NodePalette = require(script.Parent.NodePalette)
local PropertyPanel = require(script.Parent.PropertyPanel)
local BranchList = require(script.Parent.BranchList)
local Modal = require(script.Parent.Parent.Components.Modal)
local Notification = require(script.Parent.Parent.Components.Notification)

local EditorState = require(script.Parent.Parent.State.EditorState)
local BranchManager = require(script.Parent.Parent.State.BranchManager)
local NodeManager = require(script.Parent.Parent.State.NodeManager)
local WireManager = require(script.Parent.Parent.State.WireManager)
local CommentManager = require(script.Parent.Parent.State.CommentManager)
local WireSnapDetector = require(script.Parent.Parent.State.WireSnapDetector)
local ActionSerializer = require(script.Parent.Parent.Serialization.ActionSerializer)

local EditorWindow = {}

export type EditorWindowConfig = {
	Parent: GuiObject,
	OnSave: ((ActionData: any) -> boolean?)?,
	OnTest: ((ActionData: any) -> ())?,
	OnLoad: ((ActionId: string) -> any?)?,
	GetActionsList: (() -> { { Id: string, Name: string } })?,
}

export type EditorWindowInstance = {
	Frame: Frame,
	LoadAction: (ActionData: any) -> (),
	NewAction: () -> (),
	GetActionData: () -> any,
	SetActionId: (NewActionId: string) -> (),
	GetActionId: () -> string,
	SetVisible: (Visible: boolean) -> (),
	Destroy: () -> (),
}

function EditorWindow.Create(Config: EditorWindowConfig): EditorWindowInstance
	EditorState.Init()

	local NodeInstances: { [string]: Node.NodeInstance } = {}
	local WireInstances: { [string]: Wire.WireInstance } = {}
	local CommentInstances: { [string]: Comment.CommentInstance } = {}
	local PreviewWire: Wire.WireInstance? = nil

	local EditorConnections: { RBXScriptConnection } = {}
	local ManagerConnections: { any } = {}

	local NodeZOrderCounter = 0

	local Container = Instance.new("Frame")
	Container.Name = "ActionEditor"
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

	local EditorInstance: EditorWindowInstance = nil :: any

	local function CollectAllPortData(): { {
		NodeId: string,
		PortName: string,
		PortType: Types.PortType,
		Direction: Types.PortDirection,
		WorldPosition: Vector2,
	} }
		local PortDataList = {}

		for NodeId, NodeUI in NodeInstances do
			local AllPorts = NodeUI.GetAllPorts()
			for PortName, PortAccessor in AllPorts do
				table.insert(PortDataList, {
					NodeId = NodeId,
					PortName = PortName,
					PortType = PortAccessor.PortType,
					Direction = PortAccessor.Direction,
					WorldPosition = PortAccessor.GetWorldPosition(),
				})
			end
		end

		return PortDataList
	end

	local function GetWiredInputsForNode(NodeId: string): { [string]: boolean }
		local WiredInputs: { [string]: boolean } = {}
		local Wires = WireManager.GetByNode(NodeId)

		for _, WireData in Wires do
			if WireData.ToNodeId == NodeId then
				WiredInputs[WireData.ToPortName] = true
			end
		end

		return WiredInputs
	end

	local function UpdatePreviewWire()
		if not PreviewWire then
			return
		end

		local ConnectionState = WireManager.GetConnectionState()
		if not ConnectionState.IsConnecting or not ConnectionState.FromNodeId then
			return
		end

		local FromNodeUI = NodeInstances[ConnectionState.FromNodeId]
		if not FromNodeUI then
			return
		end

		local FromPort = FromNodeUI.GetPort(ConnectionState.FromPortName :: string)
		if not FromPort then
			return
		end

		local StartPos = FromPort.GetWorldPosition()
		local MousePosition = UserInputService:GetMouseLocation()
		local GuiInset = GuiService:GetGuiInset()
		MousePosition = MousePosition - GuiInset

		local PortDataList = CollectAllPortData()

		local SnapTarget = WireSnapDetector.FindNearestCompatiblePort(
			MousePosition,
			ConnectionState.FromNodeId,
			ConnectionState.FromPortType :: Types.PortType,
			ConnectionState.FromDirection :: Types.PortDirection,
			PortDataList
		)

		WireSnapDetector.UpdateSnapState(SnapTarget)

		local EndPos = MousePosition
		if SnapTarget then
			EndPos = SnapTarget.WorldPosition
		end

		PreviewWire.SetSnapped(SnapTarget ~= nil)
		PreviewWire.SetPositions(StartPos, EndPos)
	end

	local function ClearPreviewWire()
		if PreviewWire then
			PreviewWire.Destroy()
			PreviewWire = nil
		end
		WireSnapDetector.ClearSnapState()
	end

	local function UpdateWirePositions()
		task.defer(function()
			for WireId, WireUI in WireInstances do
				local WireData = WireManager.GetById(WireId)
				if not WireData then
					continue
				end

				local FromNodeUI = NodeInstances[WireData.FromNodeId]
				local ToNodeUI = NodeInstances[WireData.ToNodeId]

				if not FromNodeUI or not ToNodeUI then
					continue
				end

				local FromPort = FromNodeUI.GetPort(WireData.FromPortName)
				local ToPort = ToNodeUI.GetPort(WireData.ToPortName)

				if not FromPort or not ToPort then
					continue
				end

				WireUI.SetPositions(FromPort.GetWorldPosition(), ToPort.GetWorldPosition())
			end
		end)
	end

	local function BringNodeToFront(NodeId: string)
		NodeZOrderCounter = NodeZOrderCounter + 1
		local NodeUI = NodeInstances[NodeId]
		if NodeUI and NodeUI.SetZOrder then
			NodeUI.SetZOrder(NodeZOrderCounter)
		end
	end

	local function CreateNodeUI(NodeData: Types.NodeInstance)
		local WiredInputs = GetWiredInputsForNode(NodeData.NodeId)

		local NodeUI = NodeFactory.CreateFromBlock(NodeData, {
			Parent = CanvasInstance.Content,
			WiredInputs = WiredInputs,
			OnSelected = function(NodeId: string)
				NodeManager.Select(NodeId)
			end,
			OnMoved = function(NodeId: string, Position: Vector2)
				NodeManager.Move(NodeId, Position)
			end,
			OnPortConnectionStart = function(NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection)
				WireManager.StartConnection(NodeId, PortName, PortType, Direction)
			end,
			OnPortConnectionEnd = function(NodeId: string, PortName: string)
				WireManager.EndConnection(NodeId, PortName)
			end,
			OnPropertyChanged = function(NodeId: string, Key: string, Value: any)
				NodeManager.SetProperty(NodeId, Key, Value)
			end,
		})

		if NodeUI then
			NodeInstances[NodeData.NodeId] = NodeUI
		end
	end

	local function CreateWireUI(WireData: Types.WireInstance)
		local WireUI = Wire.Create({
			WireId = WireData.WireId,
			WireType = WireData.WireType,
			ValueType = WireData.ValueType,
			Parent = CanvasInstance.Content,
			OnClick = function(ClickedWireId: string)
				WireManager.Delete(ClickedWireId)
			end,
			CanInteract = function()
				return not WireManager.IsConnecting()
			end,
		})

		WireInstances[WireData.WireId] = WireUI
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
				CommentManager.Select(CommentId)
			end,
			OnMoved = function(CommentId: string, Position: Vector2)
				CommentManager.Move(CommentId, Position)
			end,
			OnResized = function(CommentId: string, Size: Vector2)
				CommentManager.Resize(CommentId, Size)
			end,
			OnTitleChanged = function(CommentId: string, Title: string)
				CommentManager.SetTitle(CommentId, Title)
			end,
			OnTextChanged = function(CommentId: string, Text: string)
				CommentManager.SetText(CommentId, Text)
			end,
		})

		CommentInstances[CommentData.CommentId] = CommentUI
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

		ClearPreviewWire()
		NodeManager.ResetSpawnCounter()
		CommentManager.ResetSpawnCounter()
		NodeZOrderCounter = 0
	end

	local function RenderCurrentBranch()
		ClearCanvas()

		local Branch = BranchManager.GetCurrent()
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
			CreateWireUI(WireData)
		end

		UpdateWirePositions()
	end

	local function ResetToNewAction()
		EditorState.Reset()
		ToolbarPanel.SetActionName("New Action")
		ToolbarPanel.SetDirty(false)
		BranchListPanel.SetBranches({})
		ClearCanvas()
	end

	ToolbarPanel = Toolbar.Create({
		Parent = Container,
		OnNew = function()
			if EditorState.IsDirty() then
				Modal.Confirm({
					Title = "Unsaved Changes",
					Message = "You have unsaved changes. Are you sure you want to create a new Action?",
					ConfirmText = "Discard",
					ConfirmColor = Theme.Colors.Error,
					Parent = Container,
					OnConfirm = function()
						ResetToNewAction()
					end,
				})
			else
				ResetToNewAction()
			end
		end,
		OnSave = function()
			if Config.OnSave then
				local ActionData = ActionSerializer.Export(EditorState.Get())
				local Success = Config.OnSave(ActionData)
				if Success ~= false then
					EditorState.ClearDirty()
					Notification.Success("Action saved successfully!", Container)
				else
					Notification.Error("Failed to save Action.", Container)
				end
			end
		end,
		OnLoad = function()
			local function ShowLoadModal()
				if not Config.GetActionsList or not Config.OnLoad then
					return
				end

				local Actions = Config.GetActionsList()
				Modal.Select({
					Title = "Load Action",
					Options = Actions,
					Parent = Container,
					OnSelected = function(OptionId: string)
						if Config.OnLoad then
							local ActionData = Config.OnLoad(OptionId)
							if ActionData then
								EditorInstance.LoadAction(ActionData)
								Notification.Success("Action loaded successfully!", Container)
							else
								Notification.Error("Failed to load Action.", Container)
							end
						end
					end,
				})
			end

			if EditorState.IsDirty() then
				Modal.Confirm({
					Title = "Unsaved Changes",
					Message = "You have unsaved changes. Are you sure you want to load a different Action?",
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
				local ActionData = ActionSerializer.Export(EditorState.Get())
				Config.OnTest(ActionData)
			end
		end,
		OnNameChanged = function(Name: string)
			EditorState.SetDisplayName(Name)
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
			EditorState.ClearSelection()
			WireManager.CancelConnection()
		end,
	})

	NodeManager.SetCanvasToWorldFunction(function(Pos: Vector2): Vector2
		return CanvasInstance.CanvasToWorld(Pos)
	end)
	CommentManager.SetCanvasToWorldFunction(function(Pos: Vector2): Vector2
		return CanvasInstance.CanvasToWorld(Pos)
	end)

	PalettePanel = NodePalette.Create({
		Parent = ContentArea,
		OnNodeSelected = function(BlockType: string)
			if BlockType == "Comment" then
				local CommentData = CommentManager.Add()
				if CommentData then
					CommentManager.Select(CommentData.CommentId)
				end
			else
				local NodeData = NodeManager.Add(BlockType)
				if NodeData then
					NodeManager.Select(NodeData.NodeId)
				end
			end
		end,
	})

	PropertiesPanel = PropertyPanel.Create({
		Parent = ContentArea,
		OnPropertyChanged = function(NodeId: string, Key: string, Value: any)
			NodeManager.SetProperty(NodeId, Key, Value)
		end,
		OnNodeDelete = function(NodeId: string)
			if NodeManager.CanDelete(NodeId) then
				WireManager.DeleteByNode(NodeId)
				NodeManager.Delete(NodeId)
			else
				Notification.Warning("Cannot delete Branch Start node.", Container)
			end
		end,
		OnCommentPropertyChanged = function(CommentId: string, Key: string, Value: any)
			if Key == "Title" then
				CommentManager.SetTitle(CommentId, Value)
			elseif Key == "Text" then
				CommentManager.SetText(CommentId, Value)
			elseif Key == "Color" then
				CommentManager.SetColor(CommentId, Value)
			end
		end,
		OnCommentDelete = function(CommentId: string)
			CommentManager.Delete(CommentId)
		end,
		GetBranchOptions = function(): { string }
			return BranchManager.GetBranchNames()
		end,
	})

	BranchListPanel = BranchList.Create({
		Parent = ContentArea,
		OnBranchSelected = function(BranchId: string)
			BranchManager.Select(BranchId)
		end,
		OnBranchCreated = function(BranchName: string)
			local BranchId = BranchManager.Create(BranchName)
			BranchManager.Select(BranchId)
		end,
		OnBranchDeleted = function(BranchId: string)
			BranchManager.Delete(BranchId)
			BranchManager.SelectFirst()
		end,
		OnBranchRenamed = function(BranchId: string, NewName: string)
			BranchManager.Rename(BranchId, NewName)
		end,
	})

	table.insert(ManagerConnections, EditorState.DirtyChanged:Connect(function(IsDirty: boolean)
		ToolbarPanel.SetDirty(IsDirty)
	end))

	table.insert(ManagerConnections, EditorState.BranchSelected:Connect(function(BranchId: string?)
		BranchListPanel.SetSelectedBranch(BranchId)
		RenderCurrentBranch()
	end))

	table.insert(ManagerConnections, EditorState.NodeSelected:Connect(function(NodeId: string?, OldNodeId: string?)
		if OldNodeId and NodeInstances[OldNodeId] then
			NodeInstances[OldNodeId].SetSelected(false)
		end

		if NodeId and NodeInstances[NodeId] then
			BringNodeToFront(NodeId)
			NodeInstances[NodeId].SetSelected(true)
			local NodeData = NodeManager.GetById(NodeId)
			PropertiesPanel.SetNode(NodeData)
		else
			PropertiesPanel.SetNode(nil)
		end
	end))

	table.insert(ManagerConnections, EditorState.CommentSelected:Connect(function(CommentId: string?, OldCommentId: string?)
		if OldCommentId and CommentInstances[OldCommentId] then
			CommentInstances[OldCommentId].SetSelected(false)
		end

		if CommentId and CommentInstances[CommentId] then
			CommentInstances[CommentId].SetSelected(true)
			local CommentData = CommentManager.GetById(CommentId)
			PropertiesPanel.SetComment(CommentData)
		else
			PropertiesPanel.SetComment(nil)
		end
	end))

	table.insert(ManagerConnections, EditorState.StateReset:Connect(function()
		BranchListPanel.SetBranches(EditorState.GetBranches())
		RenderCurrentBranch()
	end))

	table.insert(ManagerConnections, BranchManager.BranchListChanged:Connect(function(Branches)
		BranchListPanel.SetBranches(Branches)
	end))

	table.insert(ManagerConnections, NodeManager.NodeAdded:Connect(function(NodeData: Types.NodeInstance)
		CreateNodeUI(NodeData)
	end))

	table.insert(ManagerConnections, NodeManager.NodeDeleted:Connect(function(NodeId: string)
		local NodeUI = NodeInstances[NodeId]
		if NodeUI then
			NodeUI.Destroy()
			NodeInstances[NodeId] = nil
		end
	end))

	table.insert(ManagerConnections, NodeManager.NodeMoved:Connect(function()
		UpdateWirePositions()
	end))

	table.insert(ManagerConnections, NodeManager.NodePropertyChanged:Connect(function(NodeId: string, Key: string, Value: any)
		local NodeUI = NodeInstances[NodeId]
		if NodeUI and NodeUI.SetPropertyValue then
			NodeUI.SetPropertyValue(Key, Value)
		end

		local SelectedNodeId = EditorState.GetSelectedNodeId()
		if NodeId == SelectedNodeId then
			PropertiesPanel.RefreshProperty(Key, Value)
		end
	end))

	table.insert(ManagerConnections, WireManager.WireCreated:Connect(function(WireData: Types.WireInstance)
		CreateWireUI(WireData)
		UpdateWirePositions()

		local ToNodeUI = NodeInstances[WireData.ToNodeId]
		if ToNodeUI and ToNodeUI.SetPortWired then
			ToNodeUI.SetPortWired(WireData.ToPortName, true)
		end
	end))

	table.insert(ManagerConnections, WireManager.WireDeleted:Connect(function(WireId: string, WireData: Types.WireInstance?)
		if WireData then
			local ToNodeUI = NodeInstances[WireData.ToNodeId]
			if ToNodeUI and ToNodeUI.SetPortWired then
				ToNodeUI.SetPortWired(WireData.ToPortName, false)
			end
		end

		local WireUI = WireInstances[WireId]
		if WireUI then
			WireUI.Destroy()
			WireInstances[WireId] = nil
		end
	end))

	table.insert(ManagerConnections, WireManager.ConnectionStarted:Connect(function(ConnectionState)
		PreviewWire = Wire.CreatePreview(CanvasInstance.Content, ConnectionState.FromPortType :: Types.PortType, ConnectionState.FromValueType)
		UpdatePreviewWire()
	end))

	table.insert(ManagerConnections, WireManager.ConnectionCanceled:Connect(function()
		ClearPreviewWire()
	end))

	table.insert(ManagerConnections, WireManager.ConnectionEnded:Connect(function()
		ClearPreviewWire()
	end))

	table.insert(ManagerConnections, WireSnapDetector.SnapChanged:Connect(function(SnapState)
		for _, NodeUI in NodeInstances do
			local AllPorts = NodeUI.GetAllPorts()
			for _, PortAccessor in AllPorts do
				PortAccessor.SetHighlighted(false)
			end
		end

		if SnapState.IsSnapped and SnapState.Target then
			local TargetNodeUI = NodeInstances[SnapState.Target.NodeId]
			if TargetNodeUI then
				local TargetPort = TargetNodeUI.GetPort(SnapState.Target.PortName)
				if TargetPort then
					TargetPort.SetHighlighted(true)
				end
			end
		end
	end))

	table.insert(ManagerConnections, CommentManager.CommentAdded:Connect(function(CommentData: Types.CommentData)
		CreateCommentUI(CommentData)
	end))

	table.insert(ManagerConnections, CommentManager.CommentDeleted:Connect(function(CommentId: string)
		local CommentUI = CommentInstances[CommentId]
		if CommentUI then
			CommentUI.Destroy()
			CommentInstances[CommentId] = nil
		end
	end))

	table.insert(ManagerConnections, CommentManager.CommentPropertyChanged:Connect(function(CommentId: string, Key: string, Value: any)
		local CommentUI = CommentInstances[CommentId]
		if CommentUI then
			if Key == "Title" then
				CommentUI.SetTitle(Value)
			elseif Key == "Text" then
				CommentUI.SetText(Value)
			elseif Key == "Color" then
				CommentUI.SetColor(Value)
			end
		end
	end))

	table.insert(EditorConnections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			UpdatePreviewWire()
		end
	end))

	table.insert(EditorConnections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if WireManager.IsConnecting() then
				local ConnectionState = WireManager.GetConnectionState()

				if ConnectionState.FromNodeId and ConnectionState.FromPortName then
					local MousePosition = UserInputService:GetMouseLocation()
					local GuiInset = GuiService:GetGuiInset()
					MousePosition = MousePosition - GuiInset

					local PortDataList = CollectAllPortData()
					local SnapTarget = WireSnapDetector.FindNearestCompatiblePort(
						MousePosition,
						ConnectionState.FromNodeId,
						ConnectionState.FromPortType :: Types.PortType,
						ConnectionState.FromDirection :: Types.PortDirection,
						PortDataList
					)

					if SnapTarget then
						WireManager.EndConnection(SnapTarget.NodeId, SnapTarget.PortName)
					else
						WireManager.CancelConnection()
					end
				else
					WireManager.CancelConnection()
				end

				WireSnapDetector.ClearSnapState()
				ClearPreviewWire()
			end
		end
	end))

	table.insert(EditorConnections, UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed then
			return
		end
		if Input.KeyCode == Enum.KeyCode.Delete or Input.KeyCode == Enum.KeyCode.Backspace then
			local SelectedCommentId = EditorState.GetSelectedCommentId()
			local SelectedNodeId = EditorState.GetSelectedNodeId()

			if SelectedCommentId then
				CommentManager.Delete(SelectedCommentId)
			elseif SelectedNodeId then
				if NodeManager.CanDelete(SelectedNodeId) then
					WireManager.DeleteByNode(SelectedNodeId)
					NodeManager.Delete(SelectedNodeId)
				else
					Notification.Warning("Cannot delete Branch Start node.", Container)
				end
			end
		end
	end))

	EditorInstance = {
		Frame = Container,
	} :: any

	function EditorInstance.LoadAction(ActionData: any)
		local NewState = ActionSerializer.Import(ActionData)
		EditorState.Set(NewState)
		ToolbarPanel.SetActionName(NewState.DisplayName)
		ToolbarPanel.SetDirty(false)
		BranchListPanel.SetBranches(NewState.Branches)

		local FirstBranchId = BranchManager.SelectFirst()
		if FirstBranchId then
			RenderCurrentBranch()
		end
	end

	function EditorInstance.NewAction()
		ResetToNewAction()
	end

	function EditorInstance.GetActionData(): any
		return ActionSerializer.Export(EditorState.Get())
	end

	function EditorInstance.SetActionId(NewActionId: string)
		EditorState.SetActionId(NewActionId)
	end

	function EditorInstance.GetActionId(): string
		return EditorState.GetActionId()
	end

	function EditorInstance.SetVisible(Visible: boolean)
		Container.Visible = Visible
	end

	function EditorInstance.Destroy()
		for _, Connection in EditorConnections do
			Connection:Disconnect()
		end
		table.clear(EditorConnections)

		for _, Connection in ManagerConnections do
			if Connection.Disconnect then
				Connection:Disconnect()
			end
		end
		table.clear(ManagerConnections)

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

return EditorWindow