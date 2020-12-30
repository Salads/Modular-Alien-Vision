
-- Defines stuff related to interfacing a alien vision mod with MAV.

Print("$ Loaded MAV_FileFetch.lua")

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

                                -- OPTIONAL, but if one is specified, all bitfield-related stuff must be for the respective parameter.
                                bitfieldId = "If this is filled out, then this parameter will be set as a 0/1 in a bitfield specified by this variable.",
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
        avTable.interfaceData = {}
        if decodedInterface.Parameters then
            for i = 1, #decodedInterface.Parameters do
                table.insert(avTable.interfaceData, decodedInterface[i])
            end
        end
        -- Its possible that a AV doesn't need any parameters.

    else
        Log("ERROR: Could not open interface file for AV: %s!", avTable.id)
        return false
    end

    return false
end

local kAVFileTypes = set
{
    "screenfx",
    "shader",
    "hlsl",
    "interface"
}

-- These are identifiers that are forbidden due to that member name being used
-- for some other purpose.
local kReservedIdentifiers = set
{
    "_skippedFiles" -- For debug information.
}

kValidStatus = enum(
{
    'Valid',
    'MissingScreenFX',
    'InvalidParameter'
})

kSkippedFileReason = enum(
{
    'UsedReservedId',
    'NoIdentifier'
})

--[[
        Puts all the files from each MAV folder into their respective table,
        each relevant file being assigned to a specific named member in the table.

        Finally, a table containing those AV-specific tables are returned.

        Validity checking of AV folders will be done after this compile step,
        however even then invalid AVs will still be passed along, so that we can
        have a nice thing that shows people debug information trying to get their AV mod working with MAV
--]]
function MAVCompileFiles(files)

    local resultTable =
    {
        _skippedFiles = {}
    }

    -- Group up all the files by their parent folder. (identifier)
    for i = 1, #files do

        local file = files[i]
        local fileAVIdentifier = MAVGetIdentifierFromPath(file)
        if fileAVIdentifier then

            local shouldAddTable = true
            if kReservedIdentifiers[fileAVIdentifier] then
                table.insert(resultTable._skippedFiles, { skippedFile = file, reason = kSkippedFileReason.UsedReservedId })
                shouldAddTable = false
            end

            if shouldAddTable then

                -- Make sure the entry exists
                if not resultTable[fileAVIdentifier] then
                    resultTable[fileAVIdentifier] =
                    {
                        id = fileAVIdentifier,
                        status = kValidStatus.Valid,
                        parameterErrors = {},
                        ignoredFiles = {},
                    }
                end

                local avTable = resultTable[fileAVIdentifier]
                local extension = file:gsub(".*[.]", "")
                if extension then

                    if kAVFileTypes[extension:lower()] then
                        avTable[extension] = file
                    else
                        table.insert(avTable.ignoredFiles, file)
                    end

                end

            end

        else
            table.insert(resultTable._skippedFiles, { skippedFile = file, reason = kSkippedFileReason.NoIdentifier })
        end

    end

    return resultTable
end

function MAVGetIdentifierFromPath(path)

    local matchedStr = path:match'/([^/]+)/'

    if matchedStr then
        return matchedStr:gsub("/", "")
    else
        return nil
    end

end

-- Gets all the files present in every mounted MAV addon mod.
function MAVGetModFiles()

    --[[
        NOTE(Salads): Shared.GetMatchingFileNames uses FindFirstFileW, which is technically a single-directory search,
        so it cannot have wildcards in the directory part, only the filename part. (Thanks, Ray!)

        However, the recursive flag passed into it makes the Spark Engine search all the directories and it's subfolders!
    --]]

    local MAVFiles = {}
    Shared.GetMatchingFileNames( "DarkVision*", true, MAVFiles )

    -- Remove all of the matching filenames that don't have the correct file structure.
    -- Ex: MAV/any_folder_name/DarkVision.*
    -- where any_folder_name is the name the AV will be referenced by.
    for i = #MAVFiles, 1, -1 do
        if not MAVFiles[i]:match'^MAV/([^/]+)/DarkVision[.]([^/]+)$' then
            table.remove(MAVFiles, i)
        end
    end

    return MAVFiles

end

function MAVRefreshAVSources()

    local files = MAVGetModFiles()
    local avTables = MAVCompileFiles(files)

    GetMAV()._AVTables = avTables

    -- TODO(Salads): Generate GUIConfigs for all of the AVs!


end
