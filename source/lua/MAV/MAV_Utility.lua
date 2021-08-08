
Print("$ Loaded MAV_Utility.lua")

function GetSetString(set)

    local first = true
    local result = ""
    for k, _ in pairs(set) do

        result = result .. string.format(first and "%s" or ", %s", k)
        first = false

    end

    return result
end

function MAVCheckType(value, requiredType)
    return type(value) == requiredType
end

function MAVGetIsArray(test)

    if type(test) ~= "table" then return false end

    local numericalKeys = {}
    for key, _ in pairs(test) do

        -- Lua arrays should have a contiguous sequence of numerical keys starting from 1.
        if type(key) ~= "number" then
            return false, string.format("Key '%s' is not a number", key)
        end

        -- Lua arrays shouldn't have identical keys.
        if table.contains(numericalKeys, key) then
            return false, "Found repeated number key"
        end

        table.insert(numericalKeys, key)

    end

    table.sort(numericalKeys)

    for i = 1, #numericalKeys do
        if i ~= numericalKeys[i] then
            return false, "Array is sparse"
        end
    end

    return true
end

function GetTableValuesString(t)

    assert( type( t ) == "table" )

    local result = ""
    local first = true

    if MAVGetIsArray(t) then
        for _, v in ipairs(t) do
            result = result .. string.format( first and "%s" or ", %s", v)
            first = false
        end
    else
        for _, v in pairs(t) do
            result = result .. string.format( first and "%s" or ", %s", v)
            first = false
        end
    end

    return result

end