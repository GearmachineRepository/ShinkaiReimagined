--!strict

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local UILibrary = require(script.Parent.Parent.UILibrary)

local Notification = {}

local SLIDE_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_DURATION = 3

export type NotificationType = "Success" | "Error" | "Warning" | "Info" | string

export type NotificationConfig = {
	Message: string,
	Type: NotificationType?,
	Duration: number?,
	Parent: Instance,
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

	local Container = UILibrary.SurfaceContainer({
		Name = "Notification",
		Size = UDim2.fromOffset(320, 0),
		Position = UDim2.new(0.5, 0, 0, -60),
		ZIndex = Theme.ZIndex.Tooltip,
		Parent = Config.Parent,
	})
	Container.AnchorPoint = Vector2.new(0.5, 0)
	Container.AutomaticSize = Enum.AutomaticSize.Y

	local Stroke = Container:FindFirstChildOfClass("UIStroke")
	if Stroke then
		Stroke.Color = TypeColor
		Stroke.Thickness = 2
	end

	UILibrary.Padding({
		All = UDim.new(0, 12),
		Parent = Container,
	})

	UILibrary.ListLayout({
		Direction = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = Container,
	})

	local Indicator = UILibrary.TransparentContainer({
		Name = "Indicator",
		Size = UDim2.fromOffset(4, 20),
		LayoutOrder = 1,
		ZIndex = Theme.ZIndex.Tooltip,
		Parent = Container,
	})
	Indicator.BackgroundTransparency = 0
	Indicator.BackgroundColor3 = TypeColor
	UILibrary.Corner(Indicator, UDim.new(0, 2))

	local MessageLabel = UILibrary.BodyLabel({
		Name = "Message",
		Text = Config.Message,
		Size = UDim2.new(1, -20, 0, 0),
		ZIndex = Theme.ZIndex.Tooltip,
		Parent = Container,
	})
	MessageLabel.LayoutOrder = 2

	local NotifInstance: NotificationInstance = {
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
			NotifInstance.Destroy()
		end)
	end

	function NotifInstance.Dismiss()
		SlideOut()
	end

	function NotifInstance.Destroy()
		Container:Destroy()
	end

	TweenService:Create(Container, SLIDE_TWEEN, {
		Position = UDim2.new(0.5, 0, 0, 12)
	}):Play()

	task.delay(Duration, function()
		SlideOut()
	end)

	return NotifInstance
end

local CurrentNotification: NotificationInstance? = nil

function Notification.Show(Config: NotificationConfig)
	if CurrentNotification then
		CurrentNotification.Dismiss()
	end

	CurrentNotification = Notification.Create(Config)
end

function Notification.Success(Message: string, Parent: Instance)
	Notification.Show({
		Message = Message,
		Type = "Success",
		Parent = Parent,
	})
end

function Notification.Error(Message: string, Parent: Instance)
	Notification.Show({
		Message = Message,
		Type = "Error",
		Parent = Parent,
	})
end

function Notification.Warning(Message: string, Parent: Instance)
	Notification.Show({
		Message = Message,
		Type = "Warning",
		Parent = Parent,
	})
end

function Notification.Info(Message: string, Parent: Instance)
	Notification.Show({
		Message = Message,
		Type = "Info",
		Parent = Parent,
	})
end

return Notification