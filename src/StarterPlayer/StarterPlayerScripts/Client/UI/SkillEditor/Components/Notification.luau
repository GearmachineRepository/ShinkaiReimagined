--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)

local Notification = {}

local SLIDE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_DURATION = 3

export type NotificationType = "Success" | "Error" | "Warning" | "Info" | string

export type NotificationConfig = {
	Message: string,
	Type: NotificationType?,
	Duration: number?,
	Parent: GuiObject,
}

export type NotificationInstance = {
	Frame: Frame,
	Dismiss: () -> (),
	Destroy: () -> (),
}

local function GetTypeColor(NotifType: NotificationType): Color3
	if NotifType == "Success" then
		return Theme.Colors.Success
	elseif NotifType == "Error" then
		return Theme.Colors.Error
	elseif NotifType == "Warning" then
		return Theme.Colors.Warning
	else
		return Theme.Colors.Primary
	end
end

function Notification.Create(Config: NotificationConfig): NotificationInstance
	local NotifType = Config.Type or "Info"
	local Duration = Config.Duration or DEFAULT_DURATION
	local TypeColor = GetTypeColor(NotifType)
	local IsDismissed = false

	local Container = Instance.new("Frame")
	Container.Name = "Notification"
	Container.Size = UDim2.fromOffset(320, 0)
	Container.Position = UDim2.new(0.5, 0, 0, -60)
	Container.AnchorPoint = Vector2.new(0.5, 0)
	Container.BackgroundColor3 = Theme.Colors.Surface
	Container.BorderSizePixel = 0
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.ZIndex = Theme.ZIndex.Tooltip
	Container.Parent = Config.Parent

	Theme.ApplyCorner(Container, Theme.Sizes.BorderRadius)
	Theme.ApplyStroke(Container, TypeColor, 2)

	local ContentPadding = Instance.new("UIPadding")
	ContentPadding.PaddingTop = UDim.new(0, 12)
	ContentPadding.PaddingBottom = UDim.new(0, 12)
	ContentPadding.PaddingLeft = UDim.new(0, 12)
	ContentPadding.PaddingRight = UDim.new(0, 12)
	ContentPadding.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.FillDirection = Enum.FillDirection.Horizontal
	ContentLayout.Padding = UDim.new(0, 8)
	ContentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ContentLayout.Parent = Container

	local Indicator = Instance.new("Frame")
	Indicator.Name = "Indicator"
	Indicator.Size = UDim2.fromOffset(4, 20)
	Indicator.BackgroundColor3 = TypeColor
	Indicator.BorderSizePixel = 0
	Indicator.LayoutOrder = 1
	Indicator.ZIndex = Theme.ZIndex.Tooltip
	Indicator.Parent = Container

	Theme.ApplyCorner(Indicator, UDim.new(0, 2))

	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Name = "Message"
	MessageLabel.Size = UDim2.new(1, -20, 0, 0)
	MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Text = Config.Message
	MessageLabel.TextColor3 = Theme.Colors.Text
	MessageLabel.FontFace = Theme.Fonts.Default
	MessageLabel.TextSize = Theme.TextSizes.Default
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextWrapped = true
	MessageLabel.LayoutOrder = 2
	MessageLabel.ZIndex = Theme.ZIndex.Tooltip
	MessageLabel.Parent = Container

	local Instance: NotificationInstance = {
		Frame = Container,
	} :: any

	local function SlideOut()
		if IsDismissed then
			return
		end
		IsDismissed = true

		TweenService:Create(Container, SLIDE_TWEEN, {
			Position = UDim2.new(0.5, 0, 0, -60)
		}):Play()

		task.delay(0.25, function()
			Instance.Destroy()
		end)
	end

	function Instance.Dismiss()
		SlideOut()
	end

	function Instance.Destroy()
		Container:Destroy()
	end

	TweenService:Create(Container, SLIDE_TWEEN, {
		Position = UDim2.new(0.5, 0, 0, 12)
	}):Play()

	task.delay(Duration, function()
		SlideOut()
	end)

	return Instance
end

local CurrentNotification: NotificationInstance? = nil

function Notification.Show(Config: NotificationConfig)
	if CurrentNotification then
		CurrentNotification.Dismiss()
	end

	CurrentNotification = Notification.Create(Config)
end

function Notification.Success(Message: string, Parent: GuiObject)
	Notification.Show({
		Message = Message,
		Type = "Success",
		Parent = Parent,
	})
end

function Notification.Error(Message: string, Parent: GuiObject)
	Notification.Show({
		Message = Message,
		Type = "Error",
		Parent = Parent,
	})
end

function Notification.Warning(Message: string, Parent: GuiObject)
	Notification.Show({
		Message = Message,
		Type = "Warning",
		Parent = Parent,
	})
end

function Notification.Info(Message: string, Parent: GuiObject)
	Notification.Show({
		Message = Message,
		Type = "Info",
		Parent = Parent,
	})
end

return Notification