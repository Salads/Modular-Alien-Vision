
-- Defines stuff related to interfacing a alien vision mod with MAV.

Print("$ Loaded MAV_Interface.lua")

-- NOTE(Salads): Example JSON Structure for an interface file.
--[[

    { -- Root JSON Object.

          "Parameters" : [
                            { -- Each Parameter is a JSON Object. Here is a description for each member.

                                -- All types can use these members. These are required.
                                name = "Parameter Name. ( Will be passed into shader exactly as specified here )",
                                label = "Parameter label, for displaying to the client. (NOT the name of the parameter in-code)",
                                default = "Default value of the parameter.",
                                guiType = "Name of the user control to use for this parameter. ( 'slider', 'dropdown', 'checkbox', 'color' )",

                                -- OPTIONAL, but if one is specified, all must be for the respective parameter.
                                bitfieldIdentifier = "If this is filled out, then this parameter will be set as a 0/1 in a bitfield specified by this variable.",
                                bitfieldIndex = "The bit index that this parameter should set. 20 MAX. (Safe(er?) side of c++ floating point decimal unit capacity)",

                                -- OPTIONAL common members.
                                tooltip = "Text that shows up when user is hovering their mouse over the control.",
                                tooltipIcon = "Path to a image to use with the tooltip.",

                                -- REQUIRED 'slider' specific options
                                minValue = "Minimum value the slider should allow.",
                                maxValue = "Maximum value the slider should allow.",

                                decimalPlaces = "Number of decimal units to include. Ex: 2 = 1.25, 3 = 1.253, etc..", -- OPTIONAL (slider), but 2 by default.

                                -- REQUIRED 'dropdown' specific options
                                choices = "A table that specifies the value a dropdown option represents, and the label for that option."

                                -- 'checkbox' specific options
                                -- No specific options!

                                -- 'color' specific options
                                -- No specific options!
                            },
                            -- And so on...
                         ]
      }

--]]

local kAVFileTypes = set
{
    "screenfx",
    "shader",
    "hlsl",
    "interface"
}

local function ProcessInterfaceFile(avTable)

    if not avTable.interface then
        Log("ERROR: interface file does not exist for AV: %s", avTable.id)
        return false
    end

    -- Open the file and parse it.
    local openedFile = io.open(avTable.interface, "r")
    if openedFile then

        local decodedInterface, _, errStr = json.decode(openedFile:read("*all"))
        io.close(openedFile)

        if errStr then
            Log("Error while decoding json file " .. avTable.interface .. ": " .. errStr)
            return false
        end

    -- TODO(Salads): Read and validate all of the decoded json here.

    else
        Log("ERROR: Could not open interface file for AV: %s!", avTable.id)
        return false
    end

    return false
end

local function ValidateAVTable(table)

    local result = true

    -- NOTE(Salads): It's possible that the author wants to use the vanilla hlsl and shader files.
    -- Just let the shader fail if they did something wrong in that case.
    -- Still need interface file, though.
    if not table.screenfx or not table.interface then
        result = false
    else
        result = ProcessInterfaceFile(table)
    end

    return result
end

--[[
        Puts all the files from each AV folder into their respective table,
        each file being assigned to a specific named member in the table.

        If a AV-specific table is not valid somehow, this will print out a
        error message a skip the av altogether.

        Finally, a table containing those AV-specific tables are returned.
--]]
function MAVCompileFiles(files)

    local resultTable = {}
    local avFoldersByIdentifier = {}

    -- Group up all the files by their parent folder. (identifier)
    for i = 1, #files do

        local file = files[i]
        local fileAVIdentifier = MAVGetIdentifierFromPath(file)
        if fileAVIdentifier then

            -- Make sure the entry exists
            if not avFoldersByIdentifier[fileAVIdentifier] then
                avFoldersByIdentifier[fileAVIdentifier] =
                {
                    id = fileAVIdentifier
                }
            end

            local avTable = avFoldersByIdentifier[fileAVIdentifier]
            local extension = file:gsub(".*[.]", "")
            if extension then

                if kAVFileTypes[extension:lower()] then
                    avTable[extension] = file
                else
                    Log("WARNING: Invalid Extension! File: '%s', Extension: '%s' ... Ignoring", file, extension)
                end

            end

        end

    end

    -- Validate all of the AV tables, and add them to their respective result tables.
    for _, avTable in pairs(avFoldersByIdentifier) do

        if ValidateAVTable(avTable) then
            table.insert(resultTable, avTable)
        end

    end

    return resultTable
end

function MAVGetIdentifierFromPath(path)

    local matchedStr = path:match'/([^/]+)/'

    if matchedStr then
        return matchedStr:gsub("/", "")
    else
        Log("ERROR: File '%s' is in the incorrect location!")
        return nil
    end

end

-- Gets all the files present in every mounted MAV addon mod.
function MAVGetModFiles()

    --[[
        NOTE(Salads): Shared.GetMatchingFileNames uses FindFirstFileW, which is technically a single-directory search,
        so it cannot have multiple wildcards in the directory part, only the filename part.
    --]]

    local MAVFiles = {}
    Shared.GetMatchingFileNames( "DarkVision*", true, MAVFiles )

    -- Remove all of the matching filenames that don't have "MAV" in them.
    for i = #MAVFiles, 1, -1 do

        Print("> Matching Filename: %s", MAVFiles[i])
        if not MAVFiles[i]:match'^MAV/([^/]+)/DarkVision[.]([^/]+)$' then
            table.remove(MAVFiles, i)
        end
    end

    return MAVFiles

end

function MAVRefreshAVSources()

    local files = MAVGetModFiles()
    local validAVs = MAVCompileFiles(files)




end

function MAVTestAVRefresh()

    Print("$ Getting Filenames")
    local files = MAVGetModFiles()

    if #files == 0 then
        Print("\tNo Files Found!")
    end

    for i = 1, #files do
        local file = files[i]
        Print("\tFile: %s, Identifier: %s", file, MAVGetIdentifierFromPath(file))
    end

    local validAVs = MAVCompileFiles(files)
    Print("$ Printing Valid AVs")
    for _, v in ipairs(validAVs) do
        Print("\t%s", v.id)
        for k, v2 in pairs(v) do
            if k ~= "id" then
                Print("\t\t%s: %s", k, v2)
            end
        end
    end

end

