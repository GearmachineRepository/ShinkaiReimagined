--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Types = require(script.Parent.Parent.Types)
local Port = require(script.Parent.Port)

local Node = {}

export type NodeConfig = {
	NodeId: string,
	BlockType: string,
	DisplayName: string,
	Color: Color3,
	Position: Vector2?,
	InputPorts: { Types.PortDefinition },
	OutputPorts: { Types.PortDefinition },
	Parent: GuiObject?,
	OnSelected: ((NodeId: string) -> ())?,
	OnMoved: ((NodeId: string, Position: Vector2) -> ())?,
	OnPortConnectionStart: ((NodeId: string, PortName: string, PortType: Types.PortType, Direction: Types.PortDirection) -> ())?,
	OnPortConnectionEnd: ((NodeId: string, PortName: string) -> ())?,
}

export type NodeInstance = {
	Frame: Frame,
	NodeId: string,
	BlockType: string,
	GetPosition: () -> Vector2,
	SetPosition: (Position: Vector2) -> (),
	SetSelected: (Selected: boolean) -> (),
	GetPort: (PortName: string) -> Port.PortInstance?,
	GetAllPorts: () -> { [string]: Port.PortInstance },
	Destroy: () -> (),
}

function Node.Create(Config: NodeConfig): NodeInstance
	local Position = Config.Position or Vector2.zero
	local Ports: { [string]: Port.PortInstance } = {}
	local IsSelected = false

	local NodeHeight = Theme.Sizes.NodeHeaderHeight
	local InputCount = #Config.InputPorts
	local OutputCount = #Config.OutputPorts
	local PortRows = math.max(InputCount, OutputCount)
	NodeHeight = NodeHeight + (PortRows * Theme.Sizes.NodePortHeight) + 8

	local Container = Instance.new("Frame")
	Container.Name = "Node_" .. Config.NodeId
	Container.Size = UDim2.fromOffset(Theme.Sizes.NodeWidth, NodeHeight)
	Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	Container.BackgroundColor3 = Theme.Colors.Surface
	Container.BorderSizePixel = 0
	Container.ZIndex = Theme.ZIndex.Node

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadiusSmall)
	local Stroke = Theme.ApplyStroke(Container, Theme.Colors.Border)

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, Theme.Sizes.NodeHeaderHeight)
	Header.BackgroundColor3 = Config.Color
	Header.BorderSizePixel = 0
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
	Title.Parent = Header

	local InputContainer = Instance.new("Frame")
	InputContainer.Name = "Inputs"
	InputContainer.Size = UDim2.new(0.5, 0, 1, -Theme.Sizes.NodeHeaderHeight)
	InputContainer.Position = UDim2.fromOffset(0, Theme.Sizes.NodeHeaderHeight)
	InputContainer.BackgroundTransparency = 1
	InputContainer.Parent = Container

	local InputLayout = Instance.new("UIListLayout")
	InputLayout.FillDirection = Enum.FillDirection.Vertical
	InputLayout.Padding = UDim.new(0, 0)
	InputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	InputLayout.Parent = InputContainer

	local OutputContainer = Instance.new("Frame")
	OutputContainer.Name = "Outputs"
	OutputContainer.Size = UDim2.new(0.5, 0, 1, -Theme.Sizes.NodeHeaderHeight)
	OutputContainer.Position = UDim2.new(0.5, 0, 0, Theme.Sizes.NodeHeaderHeight)
	OutputContainer.BackgroundTransparency = 1
	OutputContainer.Parent = Container

	local OutputLayout = Instance.new("UIListLayout")
	OutputLayout.FillDirection = Enum.FillDirection.Vertical
	OutputLayout.Padding = UDim.new(0, 0)
	OutputLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	OutputLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	OutputLayout.Parent = OutputContainer

	for Index, PortDef in Config.InputPorts do
		local PortInstance = Port.Create({
			Name = PortDef.Name,
			Direction = "Input",
			PortType = PortDef.PortType,
			NodeId = Config.NodeId,
			Parent = InputContainer,
			OnConnectionStart = function()
				if Config.OnPortConnectionStart then
					Config.OnPortConnectionStart(Config.NodeId, PortDef.Name, PortDef.PortType, "Input")
				end
			end,
			OnConnectionEnd = function()
				if Config.OnPortConnectionEnd then
					Config.OnPortConnectionEnd(Config.NodeId, PortDef.Name)
				end
			end,
		})
		PortInstance.Frame.LayoutOrder = Index
		Ports[PortDef.Name] = PortInstance
	end

	for Index, PortDef in Config.OutputPorts do
		local PortInstance = Port.Create({
			Name = PortDef.Name,
			Direction = "Output",
			PortType = PortDef.PortType,
			NodeId = Config.NodeId,
			Parent = OutputContainer,
			OnConnectionStart = function()
				if Config.OnPortConnectionStart then
					Config.OnPortConnectionStart(Config.NodeId, PortDef.Name, PortDef.PortType, "Output")
				end
			end,
			OnConnectionEnd = function()
				if Config.OnPortConnectionEnd then
					Config.OnPortConnectionEnd(Config.NodeId, PortDef.Name)
				end
			end,
		})
		PortInstance.Frame.LayoutOrder = Index
		Ports[PortDef.Name] = PortInstance
	end

	if Config.Parent then
		Container.Parent = Config.Parent
	end

	local Connections: { RBXScriptConnection } = {}
	local IsDragging = false
	local DragStartPosition = Vector2.zero
	local DragStartMouse = Vector2.zero

	table.insert(Connections, Header.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = true
			DragStartPosition = Position
			DragStartMouse = Vector2.new(Input.Position.X, Input.Position.Y)

			Container.ZIndex = Theme.ZIndex.NodeSelected

			if Config.OnSelected then
				Config.OnSelected(Config.NodeId)
			end
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(Input: InputObject)
		if IsDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local CurrentMouse = Vector2.new(Input.Position.X, Input.Position.Y)
			local Delta = CurrentMouse - DragStartMouse

			local Parent = Container.Parent :: GuiObject?
			local Zoom = 1
			if Parent and Parent:FindFirstAncestor("Canvas") then
				local CanvasContent = Parent
				Zoom = CanvasContent.Size.X.Scale
				if Zoom == 0 then
					Zoom = 1
				end
			end

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
				Container.ZIndex = Theme.ZIndex.Node
			end
		end
	end))

	local Instance: NodeInstance = {
		Frame = Container,
		NodeId = Config.NodeId,
		BlockType = Config.BlockType,
	} :: any

	function Instance.GetPosition(): Vector2
		return Position
	end

	function Instance.SetPosition(NewPosition: Vector2)
		Position = NewPosition
		Container.Position = UDim2.fromOffset(Position.X, Position.Y)
	end

	function Instance.SetSelected(Selected: boolean)
		IsSelected = Selected
		if Selected then
			Stroke.Color = Theme.Colors.BorderFocus
			Stroke.Thickness = 2
			Container.ZIndex = Theme.ZIndex.NodeSelected
		else
			Stroke.Color = Theme.Colors.Border
			Stroke.Thickness = 1
			Container.ZIndex = Theme.ZIndex.Node
		end
	end

	function Instance.GetPort(PortName: string): Port.PortInstance?
		return Ports[PortName]
	end

	function Instance.GetAllPorts(): { [string]: Port.PortInstance }
		return Ports
	end

	function Instance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)

		for _, PortInstance in Ports do
			PortInstance.Destroy()
		end
		table.clear(Ports)

		Container:Destroy()
	end

	return Instance
end

return Node