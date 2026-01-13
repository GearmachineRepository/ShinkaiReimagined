--!strict

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)
local DropdownState = require(script.Parent.Parent.State.DropdownState)

local Dropdown = {}

export type DropdownConfig = {
	Name: string?,
	Options: { string },
	Selected: string?,
	Placeholder: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: GuiObject?,
	OnSelected: ((Option: string) -> ())?,
}

export type DropdownInstance = {
	Frame: Frame,
	GetSelected: () -> string?,
	SetSelected: (Option: string?) -> (),
	SetOptions: (Options: { string }) -> (),
	Destroy: () -> (),
}

function Dropdown.Create(Config: DropdownConfig): DropdownInstance
	local Options = Config.Options or {}
	local SelectedOption = Config.Selected
	local IsOpen = false
	local CurrentDropdownId: string? = nil
	local BaseZIndex = Config.ZIndex or Theme.ZIndex.Panel

	local DropdownParts = UILibrary.DropdownButton({
		Name = Config.Name or "Dropdown",
		Size = Config.Size or UDim2.new(1, 0, 0, Theme.Sizes.InputHeight),
		Position = Config.Position,
		Text = SelectedOption,
		Placeholder = Config.Placeholder or "Select...",
		LayoutOrder = Config.LayoutOrder or 0,
		ZIndex = BaseZIndex,
		Parent = Config.Parent,
	})

	local Container = DropdownParts.Container
	local Button = DropdownParts.Button
	local Arrow = DropdownParts.Arrow

	if Config.AnchorPoint then
		Container.AnchorPoint = Config.AnchorPoint
	end

	local Connections: { RBXScriptConnection } = {}
	local OptionButtons: { TextButton } = {}
	local OptionsList: ScrollingFrame? = nil
	local Backdrop: TextButton? = nil

	local function CloseDropdown()
		if CurrentDropdownId then
			DropdownState.Close(CurrentDropdownId)
			CurrentDropdownId = nil
		end
		IsOpen = false
		Arrow.Text = "▼"

		if OptionsList then
			OptionsList:Destroy()
			OptionsList = nil
		end

		if Backdrop then
			Backdrop:Destroy()
			Backdrop = nil
		end

		table.clear(OptionButtons)
	end

	local function SelectOption(Option: string)
		SelectedOption = Option
		Button.Text = Option
		Button.TextColor3 = Theme.Colors.Text
		CloseDropdown()

		if Config.OnSelected then
			Config.OnSelected(Option)
		end
	end

	local function OpenDropdown()
		if #Options == 0 then
			return
		end

		CurrentDropdownId = DropdownState.Open()
		IsOpen = true
		Arrow.Text = "▲"

		local ScreenGui = Container:FindFirstAncestorOfClass("ScreenGui")
		if not ScreenGui then
			return
		end

		Backdrop = UILibrary.DropdownBackdrop({
			ZIndex = Theme.ZIndex.Dropdown - 1,
			Parent = ScreenGui,
		})
		if not Backdrop then return end
		Backdrop.MouseButton1Click:Connect(function()
			CloseDropdown()
		end)

		local ListHeight = math.min(#Options * Theme.Sizes.InputHeight + 4, 200)

		local ContainerAbsPos = Container.AbsolutePosition
		local ContainerAbsSize = Container.AbsoluteSize

		OptionsList = UILibrary.DropdownList({
			Size = UDim2.fromOffset(ContainerAbsSize.X, ListHeight),
			Position = UDim2.fromOffset(ContainerAbsPos.X, ContainerAbsPos.Y + ContainerAbsSize.Y + 2),
			ZIndex = Theme.ZIndex.Dropdown,
			Parent = ScreenGui,
		})

		for Index, Option in pairs(Options) do
			local OptionButton = UILibrary.DropdownOption({
				Text = Option,
				Selected = Option == SelectedOption,
				LayoutOrder = Index,
				ZIndex = Theme.ZIndex.Dropdown + 1,
				Parent = OptionsList,
			})

			OptionButton.MouseEnter:Connect(function()
				OptionButton.BackgroundTransparency = 0
				OptionButton.BackgroundColor3 = Theme.Colors.SurfaceHover
			end)

			OptionButton.MouseLeave:Connect(function()
				OptionButton.BackgroundTransparency = 1
			end)

			OptionButton.MouseButton1Click:Connect(function()
				SelectOption(Option)
			end)

			table.insert(OptionButtons, OptionButton)
		end
	end

	local function RebuildOptions()
		if IsOpen then
			CloseDropdown()
			OpenDropdown()
		end
	end

	table.insert(Connections, Button.MouseButton1Click:Connect(function()
		if IsOpen then
			CloseDropdown()
		else
			OpenDropdown()
		end
	end))

	table.insert(Connections, Button.MouseEnter:Connect(function()
		Button.BackgroundColor3 = Theme.Colors.SurfaceHover
	end))

	table.insert(Connections, Button.MouseLeave:Connect(function()
		Button.BackgroundColor3 = Theme.Colors.BackgroundDark
	end))

	local DropdownInstance: DropdownInstance = {
		Frame = Container,
	} :: any

	function DropdownInstance.GetSelected(): string?
		return SelectedOption
	end

	function DropdownInstance.SetSelected(Option: string?)
		SelectedOption = Option
		if Option then
			Button.Text = Option
			Button.TextColor3 = Theme.Colors.Text
		else
			Button.Text = Config.Placeholder or "Select..."
			Button.TextColor3 = Theme.Colors.TextMuted
		end
	end

	function DropdownInstance.SetOptions(NewOptions: { string })
		Options = NewOptions
		RebuildOptions()
	end

	function DropdownInstance.Destroy()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		CloseDropdown()
		table.clear(Connections)
		table.clear(OptionButtons)
		Container:Destroy()
	end

	return DropdownInstance
end

return Dropdown