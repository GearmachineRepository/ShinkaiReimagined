--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Packages = require(Shared.Packages)

local Log = Packages.Log

local IsServer = RunService:IsServer()
local Context = IsServer and "Server" or "Client"

local CombatLogger = Log.new()

CombatLogger:SetContext(string.format("[Combat:%s]", Context))

return CombatLogger