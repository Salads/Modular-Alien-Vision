
-- Defines stuff related to interfacing a alien vision mod with MAV.

Print("$ Loaded MAV_FileFetch.lua")

Script.Load("lua/MAV_Globals.lua")

local kAVFileTypes = set
{
    "screenfx",
    "shader",
    "hlsl",
    "interface"
}

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
                        ignoredFiles = {},
                        fileSetupErrors = {},
                        parametersErrors =
                        {
                            conflicts = {}
                        }
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
