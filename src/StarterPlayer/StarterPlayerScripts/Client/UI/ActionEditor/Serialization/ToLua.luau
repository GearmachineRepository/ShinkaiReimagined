--!strict

local ActionSerializer = {}

local function SerializeValue(Value: any, Indent: number): string
	local IndentStr = string.rep("\t", Indent)
	local NextIndent = string.rep("\t", Indent + 1)

	if type(Value) == "nil" then
		return "null"

	elseif type(Value) == "boolean" then
		return tostring(Value)

	elseif type(Value) == "number" then
		if Value == math.floor(Value) then
			return tostring(Value)
		else
			return string.format("%.4f", Value):gsub("%.?0+$", "")
		end

	elseif type(Value) == "string" then
		local Escaped = Value
			:gsub("\\", "\\\\")
			:gsub("\"", "\\\"")
			:gsub("\n", "\\n")
			:gsub("\r", "\\r")
			:gsub("\t", "\\t")
		return string.format('"%s"', Escaped)

	elseif type(Value) == "table" then
		local IsArray = #Value > 0 or next(Value) == nil
		local HasNumericKeys = false

		for Key in Value do
			if type(Key) == "number" then
				HasNumericKeys = true
				break
			end
		end

		if HasNumericKeys and not next(Value, #Value > 0 and #Value or nil) then
			IsArray = true
		end

		if IsArray then
			if #Value == 0 then
				return "[]"
			end

			local Parts = {}
			for _, Item in Value do
				table.insert(Parts, NextIndent .. SerializeValue(Item, Indent + 1))
			end

			return "[\n" .. table.concat(Parts, ",\n") .. "\n" .. IndentStr .. "]"
		else
			local Keys = {}
			for Key in Value do
				table.insert(Keys, Key)
			end
			table.sort(Keys, function(KeyA, KeyB)
				local OrderA = GetKeyOrder(KeyA)
				local OrderB = GetKeyOrder(KeyB)
				if OrderA ~= OrderB then
					return OrderA < OrderB
				end
				return tostring(KeyA) < tostring(KeyB)
			end)

			if #Keys == 0 then
				return "{}"
			end

			local Parts = {}
			for _, Key in Keys do
				local KeyStr = string.format('"%s"', tostring(Key))
				local ValueStr = SerializeValue(Value[Key], Indent + 1)
				table.insert(Parts, NextIndent .. KeyStr .. ": " .. ValueStr)
			end

			return "{\n" .. table.concat(Parts, ",\n") .. "\n" .. IndentStr .. "}"
		end

	elseif typeof(Value) == "Color3" then
		return string.format('{"r": %d, "g": %d, "b": %d}',
			math.floor(Value.R * 255),
			math.floor(Value.G * 255),
			math.floor(Value.B * 255)
		)

	elseif typeof(Value) == "Vector3" then
		return string.format('{"x": %.4f, "y": %.4f, "z": %.4f}', Value.X, Value.Y, Value.Z)
			:gsub("%.?0+([,}])", "%1")

	elseif typeof(Value) == "Vector2" then
		return string.format('{"x": %.4f, "y": %.4f}', Value.X, Value.Y)
			:gsub("%.?0+([,}])", "%1")

	elseif typeof(Value) == "UDim2" then
		return string.format('{"xScale": %.4f, "xOffset": %d, "yScale": %.4f, "yOffset": %d}',
			Value.X.Scale, Value.X.Offset, Value.Y.Scale, Value.Y.Offset)
			:gsub("%.?0+([,}])", "%1")

	else
		return string.format('"%s"', tostring(Value))
	end
end

local KEY_ORDER = {
	ActionId = 1,
	DisplayName = 2,
	Conditions = 3,
	Properties = 4,
	Timeline = 5,
	Branches = 6,
	Nodes = 7,
	Wires = 8,
	EditorData = 9,

	Entry = 10,
	BlockType = 11,
	NodeId = 12,
	WireId = 13,

	From = 20,
	FromNode = 21,
	FromPort = 22,
	To = 23,
	ToNode = 24,
	ToPort = 25,

	X = 30,
	Y = 31,
	Z = 32,
	SizeX = 33,
	SizeY = 34,
	SizeZ = 35,

	Damage = 40,
	Stun = 41,
	Time = 42,
	Speed = 43,
	Volume = 44,

	AnimationId = 50,
	SoundId = 51,
	SignalId = 52,
	BranchName = 53,

	Outputs = 90,
	RequireSignal = 91,
}

function GetKeyOrder(Key: string): number
	return KEY_ORDER[Key] or 100
end

function ActionSerializer.ToJson(ActionData: any): string
	return SerializeValue(ActionData, 0)
end

function ActionSerializer.ToLua(ActionData: any): string
	local function SerializeLua(Value: any, Indent: number): string
		local IndentStr = string.rep("\t", Indent)
		local NextIndent = string.rep("\t", Indent + 1)

		if type(Value) == "nil" then
			return "nil"

		elseif type(Value) == "boolean" then
			return tostring(Value)

		elseif type(Value) == "number" then
			if Value == math.floor(Value) then
				return tostring(Value)
			else
				return string.format("%.4f", Value):gsub("%.?0+$", "")
			end

		elseif type(Value) == "string" then
			if Value:match("^[%w_]+$") then
				return string.format('"%s"', Value)
			else
				local Escaped = Value
					:gsub("\\", "\\\\")
					:gsub("\"", "\\\"")
					:gsub("\n", "\\n")
				return string.format('"%s"', Escaped)
			end

		elseif type(Value) == "table" then
			local IsArray = true
			local MaxIndex = 0

			for Key, _ in Value do
				if type(Key) ~= "number" or Key < 1 or Key ~= math.floor(Key) then
					IsArray = false
					break
				end
				MaxIndex = math.max(MaxIndex, Key)
			end

			if IsArray and MaxIndex > 0 then
				for Index = 1, MaxIndex do
					if Value[Index] == nil then
						IsArray = false
						break
					end
				end
			end

			if IsArray and MaxIndex == 0 then
				IsArray = next(Value) == nil
			end

			if IsArray then
				if MaxIndex == 0 then
					return "{}"
				end

				local Parts = {}
				for Index = 1, MaxIndex do
					table.insert(Parts, NextIndent .. SerializeLua(Value[Index], Indent + 1))
				end

				return "{\n" .. table.concat(Parts, ",\n") .. ",\n" .. IndentStr .. "}"
			else
				local Keys = {}
				for Key in Value do
					table.insert(Keys, Key)
				end
				table.sort(Keys, function(KeyA, KeyB)
					local OrderA = GetKeyOrder(tostring(KeyA))
					local OrderB = GetKeyOrder(tostring(KeyB))
					if OrderA ~= OrderB then
						return OrderA < OrderB
					end
					return tostring(KeyA) < tostring(KeyB)
				end)

				if #Keys == 0 then
					return "{}"
				end

				local Parts = {}
				for _, Key in Keys do
					local KeyStr
					if type(Key) == "string" and Key:match("^[%a_][%w_]*$") then
						KeyStr = Key
					else
						KeyStr = string.format("[%s]", SerializeLua(Key, 0))
					end
					local ValueStr = SerializeLua(Value[Key], Indent + 1)
					table.insert(Parts, NextIndent .. KeyStr .. " = " .. ValueStr)
				end

				return "{\n" .. table.concat(Parts, ",\n") .. ",\n" .. IndentStr .. "}"
			end

		else
			return string.format('"%s"', tostring(Value))
		end
	end

	return "--!strict\n\nreturn " .. SerializeLua(ActionData, 0) .. "\n"
end

return ActionSerializer