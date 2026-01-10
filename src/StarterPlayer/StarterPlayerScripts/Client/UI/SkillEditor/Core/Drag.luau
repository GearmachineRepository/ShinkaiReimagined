--!strict

local UserInputService = game:GetService("UserInputService")

local Drag = {}

export type DragConfig = {
	Target: GuiObject,
	Handle: GuiObject?,
	ConstrainToParent: boolean?,
	GridSnap: number?,
	OnDragStart: ((Position: Vector2) -> ())?,
	OnDragMove: ((Position: Vector2, Delta: Vector2) -> ())?,
	OnDragEnd: ((Position: Vector2) -> ())?,
}

export type DragInstance = {
	SetEnabled: (Enabled: boolean) -> (),
	IsEnabled: () -> boolean,
	IsDragging: () -> boolean,
	Destroy: () -> (),
}

function Drag.Create(Config: DragConfig): DragInstance
	local Target = Config.Target
	local Handle = Config.Handle or Target
	local ConstrainToParent = Config.ConstrainToParent or false
	local GridSnap = Config.GridSnap

	local Enabled = true
	local Dragging = false
	local DragStartPosition: Vector2 = Vector2.zero
	local DragStartMousePosition: Vector2 = Vector2.zero

	local Connections: { RBXScriptConnection } = {}

	local function GetMousePosition(): Vector2
		return UserInputService:GetMouseLocation()
	end

	local function SnapToGrid(Value: number): number
		if not GridSnap or GridSnap <= 0 then
			return Value
		end
		return math.round(Value / GridSnap) * GridSnap
	end

	local function ConstrainPosition(Position: Vector2): Vector2
		if not ConstrainToParent then
			return Position
		end

		local Parent = Target.Parent :: GuiObject?
		if not Parent then
			return Position
		end

		local ParentSize = Parent.AbsoluteSize
		local TargetSize = Target.AbsoluteSize

		local MinX = 0
		local MinY = 0
		local MaxX = ParentSize.X - TargetSize.X
		local MaxY = ParentSize.Y - TargetSize.Y

		return Vector2.new(
			math.clamp(Position.X, MinX, MaxX),
			math.clamp(Position.Y, MinY, MaxY)
		)
	end

	local function OnInputBegan(Input: InputObject)
		if not Enabled then
			return
		end

		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		Dragging = true
		DragStartPosition = Target.AbsolutePosition
		DragStartMousePosition = GetMousePosition()

		if Config.OnDragStart then
			Config.OnDragStart(DragStartPosition)
		end
	end

	local function OnInputChanged(Input: InputObject)
		if not Dragging then
			return
		end

		if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local CurrentMousePosition = GetMousePosition()
		local Delta = CurrentMousePosition - DragStartMousePosition
		local NewPosition = DragStartPosition + Delta

		NewPosition = Vector2.new(SnapToGrid(NewPosition.X), SnapToGrid(NewPosition.Y))
		NewPosition = ConstrainPosition(NewPosition)

		local Parent = Target.Parent :: GuiObject?
		if Parent then
			local ParentPosition = Parent.AbsolutePosition
			local RelativePosition = NewPosition - ParentPosition
			Target.Position = UDim2.fromOffset(RelativePosition.X, RelativePosition.Y)
		end

		if Config.OnDragMove then
			Config.OnDragMove(NewPosition, Delta)
		end
	end

	local function OnInputEnded(Input: InputObject)
		if not Dragging then
			return
		end

		if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		Dragging = false

		if Config.OnDragEnd then
			Config.OnDragEnd(Target.AbsolutePosition)
		end
	end

	table.insert(Connections, Handle.InputBegan:Connect(OnInputBegan))
	table.insert(Connections, UserInputService.InputChanged:Connect(OnInputChanged))
	table.insert(Connections, UserInputService.InputEnded:Connect(OnInputEnded))

	local Instance = {}

	function Instance.SetEnabled(NewEnabled: boolean)
		Enabled = NewEnabled
		if not Enabled and Dragging then
			Dragging = false
		end
	end

	function Instance.IsEnabled(): boolean
		return Enabled
	end

	function Instance.IsDragging(): boolean
		return Dragging
	end

	function Instance.Destroy()
		Dragging = false
		Enabled = false
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)
	end

	return Instance
end

return Drag