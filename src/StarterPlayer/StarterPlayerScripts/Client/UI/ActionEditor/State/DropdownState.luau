--!strict

local HttpService = game:GetService("HttpService")

local DropdownState = {}

local OpenDropdowns: { [string]: boolean } = {}

function DropdownState.Open(DropdownId: string?): string
	local Id = DropdownId or HttpService:GenerateGUID(false)
	OpenDropdowns[Id] = true
	return Id
end

function DropdownState.Close(DropdownId: string)
	OpenDropdowns[DropdownId] = nil
end

function DropdownState.IsAnyOpen(): boolean
	return next(OpenDropdowns) ~= nil
end

function DropdownState.CloseAll()
	table.clear(OpenDropdowns)
end

return DropdownState