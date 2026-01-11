--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local NodeRow = require(script.Parent.NodeRow)

local Node = {}

export type NodeConfig = {
	NodeId: string,
	BlockType: string,
	DisplayName: string,
	Color: Color3,
	Position: Vector2?,
	InputPorts: { Types.PortDefinition },
	OutputPorts: { Types.PortDefinition },
	Properties: { [string]: any }?,
	PropertyDefinitions: { Types.PropertyDefinition }?,
	WiredInputs: { [string]: boolean }?,
	Parent: GuiObject?,
	OnSelected: ((NodeId: string) -> ())?,
	OnMoved: ((NodeId: string, Position: Vector2) -> ())?,
	OnPortConnectionStart: ((NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection) -> ())?,
	OnPortConnectionEnd: ((NodeId: string, PortName: string) -> ())?,
	OnPropertyChanged: ((NodeId: string, Key: string, Value: any) -> ())?,
}

export type PortAccessor = {
	GetWorldPosition: () -> Vector2,
	NodeId: string,
	PortName: string,
	Direction: Types.PortDirection,
	PortType: Types.PortType,
	SetHighlighted: (Highlighted: boolean) -> (),
}

export type NodeInstance = {
	Frame: Frame,
	NodeId: string,
	BlockType: string,
	GetPosition: () -> Vector2,
	SetPosition: (Position: Vector2) -> (),
	SetSelected: (Selected: boolean) -> (),
	SetZOrder: (Order: number) -> (),
	GetPort: (PortName: string) -> PortAccessor?,
	GetAllPorts: () -> { [string]: PortAccessor },
	SetPortWired: (PortName: string, Wired: boolean) -> (),
	SetPropertyValue: (Key: string, Value: any) -> (),
	Destroy: () -> (),
}

function Node.Create(Config: NodeConfig): NodeInstance
	local Position = Config.Position or Vector2.zero
	local Rows: { [string]: NodeRow.RowInstance } = {}
	local PortToRow: { [string]: NodeRow.RowInstance } = {}
	local PropertyToRow: { [string]: NodeRow.RowInstance } = {}
	local IsSelected = false
	local Connections: { RBXScriptConnection } = {}

	local PortPropertyMap: { [string]: Types.PropertyDefinition } = {}
	if Config.PropertyDefinitions then
		for _, PortDef in Config.InputPorts do
			if PortDef.PropertyKey then
				for _, PropDef in Config.PropertyDefinitions do
					if PropDef.Key == PortDef.PropertyKey then
						PortPropertyMap[PortDef.Name] = PropDef
						break
					end
				end
			end
		end
	end

	local PropertiesWithoutPort: { Types.PropertyDefinition } = {}
	if Config.PropertyDefinitions then
		for _, PropDef in Config.PropertyDefinitions do
			local HasPort = false
			for _, PortDef in Config.InputPorts do
				if PortDef.PropertyKey == PropDef.Key then
					HasPort = true
					break
				end
			end
			if not HasPort then
				table.insert(PropertiesWithoutPort, PropDef)
			end
		end
	end

	local InputCount = #Config.InputPorts
	local OutputCount = #Config.OutputPorts
	local StandalonePropertyCount = #PropertiesWithoutPort
	local MaxPortRows = math.max(InputCount, OutputCount)

	local ROW_HEIGHT = 22
	local NodeHeight = Theme.Sizes.NodeHeaderHeight + 4
	NodeHeight = NodeHeight + (MaxPortRows * ROW_HEIGHT)
	if StandalonePropertyCount > 0 then
		NodeHeight = NodeHeight + 4 + (StandalonePropertyCount * ROW_HEIGHT)
	end
	NodeHeight = NodeHeight + 4

	local Container = Instance.new("Frame")
	Container.Name = "Node_" .. Config.NodeId
	Container.Size = UDim2.fromOffset(Theme.Sizes.NodeWidth, NodeHeight)
	Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	Container.BackgroundColor3 = Theme.Colors.Surface
	Container.BorderSizePixel = 0
	Container.ZIndex = Theme.ZIndex.Node
	Container.ClipsDescendants = false
	Container.Active = true

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusSmall)
	local Stroke = Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, Theme.Sizes.NodeHeaderHeight)
	Header.BackgroundColor3 = Config.Color
	Header.BorderSizePixel = 0
	Header.ZIndex = Theme.ZIndex.NodeHeader
	Header.Active = false
	Header.Parent = Container

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = Theme.Sizes.BorderRadiusSmall
	HeaderCorner.Parent = Header

	local HeaderMask = Instance.new("Frame")
	HeaderMask.Name = "HeaderMask"
	HeaderMask.Size = UDim2.new(1, 0, 0, 8)
	HeaderMask.Position = UDim2.new(0, 0, 1, -8)
	HeaderMask.BackgroundColor3 = Config.Color
	HeaderMask.BorderSizePixel = 0
	HeaderMask.ZIndex = Theme.ZIndex.NodeHeader
	HeaderMask.Active = false
	HeaderMask.Parent = Header

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, -16, 1, 0)
	Title.Position = UDim2.fromOffset(8, 0)
	Title.BackgroundTransparency = 1
	Title.Text = Config.DisplayName
	Title.TextColor3 = Theme.Colors.Text
	Title.FontFace = Theme.Fonts.Bold
	Title.TextSize = Theme.TextSizes.Small
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.ZIndex = Theme.ZIndex.NodeHeader
	Title.Parent = Header

	local InputContainer = Instance.new("Frame")
	InputContainer.Name = "Inputs"
	InputContainer.Size = UDim2.new(0.5, 0, 0, MaxPortRows * ROW_HEIGHT)
	InputContainer.Position = UDim2.fromOffset(0, Theme.Sizes.NodeHeaderHeight + 2)
	InputContainer.BackgroundTransparency = 1
	InputContainer.ZIndex = Theme.ZIndex.NodeContent
	InputContainer.ClipsDescendants = false
	InputContainer.Parent = Container

	local InputLayout = Instance.new("UIListLayout")
	InputLayout.FillDirection = Enum.FillDirection.Vertical
	InputLayout.Padding = UDim.new(0, 0)
	InputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	InputLayout.Parent = InputContainer

	local OutputContainer = Instance.new("Frame")
	OutputContainer.Name = "Outputs"
	OutputContainer.Size = UDim2.new(0.5, 0, 0, MaxPortRows * ROW_HEIGHT)
	OutputContainer.Position = UDim2.new(0.5, 0, 0, Theme.Sizes.NodeHeaderHeight + 2)
	OutputContainer.BackgroundTransparency = 1
	OutputContainer.ZIndex = Theme.ZIndex.NodeContent
	OutputContainer.ClipsDescendants = false
	OutputContainer.Parent = Container

	local OutputLayout = Instance.new("UIListLayout")
	OutputLayout.FillDirection = Enum.FillDirection.Vertical
	OutputLayout.Padding = UDim.new(0, 0)
	OutputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	OutputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	OutputLayout.Parent = OutputContainer

	for Index, PortDef in Config.InputPorts do
		local PropDef = PortPropertyMap[PortDef.Name]
		local PropValue = nil
		if PropDef and Config.Properties then
			PropValue = Config.Properties[PropDef.Key]
			if PropValue == nil then
				PropValue = PropDef.Default
			end
		end

		local IsWired = Config.WiredInputs and Config.WiredInputs[PortDef.Name] or false

		local Row = NodeRow.Create({
			RowType = "InputPort",
			NodeId = Config.NodeId,
			PortName = PortDef.Name,
			PortType = PortDef.PortType,
			PropertyDef = PropDef,
			PropertyValue = PropValue,
			IsWired = IsWired,
			Parent = InputContainer,
			ZIndex = Theme.ZIndex.NodeContent,
			OnConnectionStart = Config.OnPortConnectionStart,
			OnConnectionEnd = Config.OnPortConnectionEnd,
			OnPropertyChanged = function(Key: string, Value: any)
				if Config.OnPropertyChanged then
					Config.OnPropertyChanged(Config.NodeId, Key, Value)
				end
			end,
		})
		Row.Frame.LayoutOrder = Index

		local RowKey = "input_" .. PortDef.Name
		Rows[RowKey] = Row
		PortToRow[PortDef.Name] = Row

		if PropDef then
			PropertyToRow[PropDef.Key] = Row
		end
	end

	for Index, PortDef in Config.OutputPorts do
		local Row = NodeRow.Create({
			RowType = "OutputPort",
			NodeId = Config.NodeId,
			PortName = PortDef.Name,
			PortType = PortDef.PortType,
			Parent = OutputContainer,
			ZIndex = Theme.ZIndex.NodeContent,
			OnConnectionStart = Config.OnPortConnectionStart,
			OnConnectionEnd = Config.OnPortConnectionEnd,
		})
		Row.Frame.LayoutOrder = Index

		local RowKey = "output_" .. PortDef.Name
		Rows[RowKey] = Row
		PortToRow[PortDef.Name] = Row
	end

	local PropertyContainer: Frame? = nil
	if StandalonePropertyCount > 0 then
		PropertyContainer = Instance.new("Frame")
		PropertyContainer.Name = "Properties"
		PropertyContainer.Size = UDim2.new(1, -8, 0, StandalonePropertyCount * ROW_HEIGHT)
		PropertyContainer.Position = UDim2.fromOffset(4, Theme.Sizes.NodeHeaderHeight + 2 + (MaxPortRows * ROW_HEIGHT) + 4)
		PropertyContainer.BackgroundTransparency = 1
		PropertyContainer.ZIndex = Theme.ZIndex.NodeContent
		PropertyContainer.ClipsDescendants = false
		PropertyContainer.Parent = Container

		local PropLayout = Instance.new("UIListLayout")
		PropLayout.FillDirection = Enum.FillDirection.Vertical
		PropLayout.Padding = UDim.new(0, 0)
		PropLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		PropLayout.Parent = PropertyContainer

		for Index, PropDef in PropertiesWithoutPort do
			local PropValue = nil
			if Config.Properties then
				PropValue = Config.Properties[PropDef.Key]
				if PropValue == nil then
					PropValue = PropDef.Default
				end
			end

			local Row = NodeRow.Create({
				RowType = "PropertyOnly",
				NodeId = Config.NodeId,
				PropertyDef = PropDef,
				PropertyValue = PropValue,
				Parent = PropertyContainer,
				ZIndex = Theme.ZIndex.NodeContent,
				OnPropertyChanged = function(Key: string, Value: any)
					if Config.OnPropertyChanged then
						Config.OnPropertyChanged(Config.NodeId, Key, Value)
					end
				end,
			})
			Row.Frame.LayoutOrder = Index

			local RowKey = "prop_" .. PropDef.Key
			Rows[RowKey] = Row
			PropertyToRow[PropDef.Key] = Row
		end
	end

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local IsDragging = false
	local DragStartPosition = Vector2.zero
	local DragStartMouse = Vector2.zero
	local ZOrderOffset = 0

	local function GetZoomScale(): number
		local Parent = Container.Parent
		if Parent then
			local UIScaleObj = Parent:FindFirstChild("ZoomScale")
			if UIScaleObj and UIScaleObj:IsA("UIScale") then
				return UIScaleObj.Scale
			end
		end
		return 1
	end

	local function UpdateZIndex(Selected: boolean)
		local BaseZ = if Selected then Theme.ZIndex.NodeSelected else Theme.ZIndex.Node
		local HeaderZ = if Selected then Theme.ZIndex.NodeSelectedHeader else Theme.ZIndex.NodeHeader
		local ContentZ = if Selected then Theme.ZIndex.NodeSelectedContent else Theme.ZIndex.NodeContent

		BaseZ = BaseZ + ZOrderOffset
		HeaderZ = HeaderZ + ZOrderOffset
		ContentZ = ContentZ + ZOrderOffset

		Container.ZIndex = BaseZ
		Header.ZIndex = HeaderZ
		HeaderMask.ZIndex = HeaderZ
		Title.ZIndex = HeaderZ
		InputContainer.ZIndex = ContentZ
		OutputContainer.ZIndex = ContentZ

		if PropertyContainer then
			PropertyContainer.ZIndex = ContentZ
		end

		for _, Row in Rows do
			Row.SetZIndex(ContentZ)
		end
	end

	UpdateZIndex(false)

	local function IsClickOnSelf(ScreenPoint: Vector2): boolean
		local PlayerGui = Container:FindFirstAncestorOfClass("PlayerGui")
		if not PlayerGui then
			return true
		end

		local GuisAtPosition = PlayerGui:GetGuiObjectsAtPosition(ScreenPoint.X, ScreenPoint.Y)

		for _, Gui in GuisAtPosition do
			if Gui == Container then
				return true
			end

			if Gui:IsDescendantOf(Container) then
				if Gui:IsA("TextButton") or Gui:IsA("ImageButton") then
					return false
				end
				continue
			end

			local GuiName = Gui.Name
			if string.sub(GuiName, 1, 5) == "Node_" then
				return false
			end

			if Gui:IsA("TextButton") or Gui:IsA("ImageButton") then
				return false
			end
		end

		return true
	end

	local function StartDrag(Input: InputObject)
		local ClickPos = Vector2.new(Input.Position.X, Input.Position.Y)
		if not IsClickOnSelf(ClickPos) then
			return
		end

		IsDragging = true
		DragStartPosition = Position
		DragStartMouse = ClickPos
		UpdateZIndex(true)

		if Config.OnSelected then
			Config.OnSelected(Config.NodeId)
		end
	end

	table.insert(Connections, Container.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StartDrag(Input)
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if IsDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local CurrentMouse = Vector2.new(Input.Position.X, Input.Position.Y)
			local Delta = CurrentMouse - DragStartMouse
			local Zoom = GetZoomScale()

			Position = DragStartPosition + (Delta / Zoom)
			Container.Position = UDim2.fromOffset(Position.X, Position.Y)

			if Config.OnMoved then
				Config.OnMoved(Config.NodeId, Position)
			end
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = false
			if not IsSelected then
				UpdateZIndex(false)
			end
		end
	end))

	local NodeInstance: NodeInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		BlockType = Config.BlockType,
	} :: any

	function NodeInstance.GetPosition(): Vector2
		return Position
	end

	function NodeInstance.SetPosition(NewPosition: Vector2)
		Position = NewPosition
		Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	end

	function NodeInstance.SetSelected(Selected: boolean)
		IsSelected = Selected
		if Selected then
			Stroke.Color = Theme.Colors.BorderFocus
			Stroke.Thickness = Theme.StrokeSizes.Selected
			UpdateZIndex(true)
		else
			Stroke.Color = Theme.Colors.Border
			Stroke.Thickness = Theme.StrokeSizes.Deslected
			UpdateZIndex(false)
		end
	end

	function NodeInstance.SetZOrder(Order: number)
		ZOrderOffset = Order * 10
		UpdateZIndex(IsSelected)
	end

	function NodeInstance.GetPort(PortName: string): PortAccessor?
		local Row = PortToRow[PortName]
		if Row and Row.GetWorldPosition then
			local WorldPos = Row.GetWorldPosition()
			if WorldPos then
				return {
					GetWorldPosition = function()
						return Row.GetWorldPosition() :: Vector2
					end,
					NodeId = Config.NodeId,
					PortName = PortName,
					Direction = Row.Direction :: Types.PortDirection,
					PortType = Row.PortType :: Types.PortType,
					SetHighlighted = function(Highlighted: boolean)
						Row.SetHighlighted(Highlighted)
					end,
				}
			end
		end
		return nil
	end

	function NodeInstance.GetAllPorts(): { [string]: PortAccessor }
		local Result: { [string]: PortAccessor } = {}
		for PortName, Row in PortToRow do
			if Row.GetWorldPosition then
				local WorldPos = Row.GetWorldPosition()
				if WorldPos then
					Result[PortName] = {
						GetWorldPosition = function()
							return Row.GetWorldPosition() :: Vector2
						end,
						NodeId = Config.NodeId,
						PortName = PortName,
						Direction = Row.Direction :: Types.PortDirection,
						PortType = Row.PortType :: Types.PortType,
						SetHighlighted = function(Highlighted: boolean)
							Row.SetHighlighted(Highlighted)
						end,
					}
				end
			end
		end
		return Result
	end

	function NodeInstance.SetPortWired(PortName: string, Wired: boolean)
		local Row = PortToRow[PortName]
		if Row then
			Row.SetWired(Wired)
		end
	end

	function NodeInstance.SetPropertyValue(Key: string, Value: any)
		local Row = PropertyToRow[Key]
		if Row then
			Row.SetPropertyValue(Value)
		end
	end

	function NodeInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)

		for _, Row in Rows do
			Row.Destroy()
		end
		table.clear(Rows)
		table.clear(PortToRow)
		table.clear(PropertyToRow)

		Container:Destroy()
	end

	return NodeInstance
end

return Node