--!strict

local DropdownState = {}

local OpenDropdownCount = 0

function DropdownState.Open()
	OpenDropdownCount = OpenDropdownCount + 1
end

function DropdownState.Close()
	OpenDropdownCount = math.max(0, OpenDropdownCount - 1)
end

function DropdownState.IsAnyOpen(): boolean
	return OpenDropdownCount > 0
end

return DropdownState