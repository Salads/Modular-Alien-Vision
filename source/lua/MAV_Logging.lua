
Print("$ Loaded MAV_Logging.lua")

Script.Load("lua/Utility.lua")

function LogErrorsForAVTables(avTables)

    MAVLog("Skipped Files (%s)", #avTables._skippedFiles)
    for j = 1, #avTables._skippedFiles do
        MAVLog("\t\t%s", avTables._skippedFiles[j])
    end

    for i = 1, #avTables do

        local invalidAV = avTables[i]

        MAVLog("%s Errors", invalidAV.id)

        MAVLog("\tIgnored Files (%s)", #invalidAV.ignoredFiles)
        for j = 1, #invalidAV.ignoredFiles do
            MAVLog("\t\t%s", invalidAV.ignoredFiles[j])
        end

        MAVLog("\tFile Setup Errors (%s)", #invalidAV.fileSetupErrors)
        for j = 1, #invalidAV.fileSetupErrors do
            MAVLog("\t\t%s", invalidAV.fileSetupErrors[j])
        end

        MAVLog("\tParameter Conflict Errors (%s)", #invalidAV.parametersErrors.conflicts)
        for j = 1, #invalidAV.parametersErrors.conflicts do
            MAVLog("\t\t%s", invalidAV.parametersErrors.conflicts[j])
        end

        MAVLog("\tParameter Errors")
        for j = 1, #invalidAV.parametersErrors do

            local parameterErrors = invalidAV.parametersErrors[j]
            if #parameterErrors > 0 then
                MAVLog("\t\tParameter Index: %s", j)
                for k = 1, #parameterErrors do
                    MAVLog("\t\t\t%s", parameterErrors[k])
                end
            end

        end

    end

end

function MAVLog(formatString, ...)

    local args = {}
    for i = 1, select('#', ...) do
        local v = select(i, ...)
        table.insert(args, ToString(v, true))
    end

    if #args > 0 then
        local str = string.format(formatString, unpack(args))
        MAV_GetLog():write(string.format("%s%s", str, "\n"))
        Print("[MAV] %s", str)
    else
        local str = string.format("%s%s", formatString, "\n")
        MAV_GetLog():write(str)
        Print("[MAV] %s", formatString)
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