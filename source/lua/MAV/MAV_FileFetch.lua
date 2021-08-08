
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
        NOTE(Salads):

        Shared.GetMatchingFileNames uses FindFirstFileW (Win32), which is technically a single-directory search,
        so it cannot have wildcards in the directory part, only the filename part. (Thanks, Ray C.!)
        https://devblogs.microsoft.com/oldnewthing/20151125-00/?p=92141

        Unfortunately, since I don't want to place naming restrictions on specific file names within a MAV addon folder,
        this means that we have to do a NON-recursive search for files in the MAV/ directory, collect the directory names,
        and search each MAV subdirectory for the respective filetypes. All because of the above reason, which means we HAVE to
        know the directory we want to search, if the files we want are in arbitrarily named sub-folders... although
        it could be a bug with engine file search and empty directory...

        have to search the file types individually, and filter them out to only files
        in the MAV folder. (Even though file types like .hlsl can be very numerous in ns2..)
    --]]

    -- Get files that are in the MAV/ directory (directories or files)
    local MAVSubFiles = {}
    Shared.GetMatchingFileNames("MAV/*", false, MAVSubFiles )

    -- Go through each sub-file and get all files that are directories
    local MAVSubFolders = {}
    for i = 1, #MAVSubFiles do
        if MAVSubFiles[i]:match('[/\\]$') then -- Also support backslash just in case.
            table.insert(MAVSubFolders, MAVSubFiles[i])
        end
    end

    -- Now get all the relevant files in each sub folder
    local allMatchingFiles = {}
    for i = 1, #MAVSubFolders do

        local folder = MAVSubFolders[i]
        Log("$ Searching in folder: %s", folder)

        -- Doesn't need recursive search, every file in each addon should be in it's own root folder.
        local searchResult = {}
        Shared.GetMatchingFileNames(string.format("%s*.hlsl",      folder), false, searchResult)
        table.addtable(searchResult, allMatchingFiles)

        Shared.GetMatchingFileNames(string.format("%s*.shader",    folder), false, searchResult)
        table.addtable(searchResult, allMatchingFiles)

        Shared.GetMatchingFileNames(string.format("%s*.screenfx",  folder), false, searchResult)
        table.addtable(searchResult, allMatchingFiles)

        Shared.GetMatchingFileNames(string.format("%s*.interface", folder), false, searchResult)
        table.addtable(searchResult, allMatchingFiles)

    end

    --local hlslFiles      = {}
    --local shaderFiles    = {}
    --local screenfxFiles  = {}
    --local interfaceFiles = {}
    --
    --Shared.GetMatchingFileNames("*.hlsl",      true, hlslFiles )
    --Shared.GetMatchingFileNames("*.shader",    true, shaderFiles )
    --Shared.GetMatchingFileNames("*.screenfx",  true, screenfxFiles )
    --Shared.GetMatchingFileNames("*.interface", true, interfaceFiles )
    --
    ----Log("$ hlsl Files(%s): '%s'", #hlslFiles, hlslFiles)
    ----Log("$ shader Files(%s): '%s'", #shaderFiles, shaderFiles)
    ----Log("$ screenfx Files(%s): '%s'", #screenfxFiles, screenfxFiles)
    ----Log("$ interface Files(%s): '%s'", #interfaceFiles, interfaceFiles)
    --
    --local allMatchingFiles = {}
    --table.addtable(hlslFiles, allMatchingFiles)
    --table.addtable(shaderFiles, allMatchingFiles)
    --table.addtable(screenfxFiles, allMatchingFiles)
    --table.addtable(interfaceFiles, allMatchingFiles)

    local MAVFiles = {}

    -- Remove all of the matching filenames that don't have the correct file structure.
    -- Ex: MAV/any_folder_name/any_file_name.*
    -- where any_folder_name is the name the AV will be referenced by.

    for i = #allMatchingFiles, 1, -1 do -- Go backwards, since we're deleting elements in-loop.
        Log("$ MAVGetModFiles - File: '%s'", allMatchingFiles[i])
        if allMatchingFiles[i]:match('^MAV/[^/]+/[^/]+[.][^/]+$') then
            table.insert(MAVFiles, allMatchingFiles[i])
        end
    end

    return MAVFiles

end
