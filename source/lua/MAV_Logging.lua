
Print("$ Loaded MAV_Logging.lua")

Script.Load("lua/Utility.lua")

function MAVLog(formatString, ...)

    local args = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(args, ToString(v, true))
    end

    if #args > 0 then
        local str = string.format(formatString, unpack(args))
        MAV_GetLog():write(string.format("%s%s", str, "\n"))
        Print("[MAV] - %s", str)
    else
        local str = string.format("%s%s", formatString, "\n")
        MAV_GetLog():write(str)
        Print("[MAV] - %s", formatString)
    end

end

kMAVLog = nil
function MAV_GetLog()

    if not kMAVLog then
        kMAVLog = io.open("config://log-MAV.txt", "w")
        assert(kMAVLog)
    end

    return kMAVLog

end

function MAV_CloseLog()

    if kMAVLog then
        io.close(kMAVLog)
    end

end

-- ClientDisconnected event happens when the world is being destroyed on the client.
Event.Hook("ClientDisconnected", MAV_CloseLog)