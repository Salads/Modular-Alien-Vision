
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