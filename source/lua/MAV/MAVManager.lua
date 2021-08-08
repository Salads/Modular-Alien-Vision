
Print("$ Loaded MAVManager.lua")

Script.Load("lua/MAV_Globals.lua")
Script.Load("lua/MAV_Logging.lua")
Script.Load("lua/MAV_Utility.lua")
Script.Load("lua/MAV_FileFetch.lua")
Script.Load("lua/MAV_Validation.lua")
Script.Load("lua/MAV_MenuGeneration.lua")
Script.Load("lua/menu2/NavBar/Screens/Options/GUIMenuOptions.lua")

Script.Load("lua/IterableDict.lua")

local kMAVManager
---@return MAVManager
function GetMAVManager()
    if not kMAVManager then
        kMAVManager = MAVManager()
        kMAVManager:Initialize()
    end

    return kMAVManager
end

---@class MAVManager
class "MAVManager"

function MAVManager:Initialize()

    self.mavs = {}
    self.errors = {}

end

--- Gets all files related to each MAV, and returns a table with each element it's own alien vision lua table,
--- which contains all the found files. No checking on these files is done with this function.
function MAVManager:RefreshMAVs()

    -- Get files that are in the MAV/ directory (directories or files)
    local subFiles = {}
    Shared.GetMatchingFileNames("MAV/*", false, subFiles )

    -- Go through each sub-file and get all files that are directories
    local subFolders = {}
    for i = 1, #MAVSubFiles do
        if subFiles[i]:match('[/\\]$') then -- Also support backslash just in case.
            table.insert(subFolders, subFiles[i])
        end
    end

    -- Now get all the relevant files by sub-folder
    local function GetFilesForFileType(fileType, folderName)
        local searchPattern = string.format("%s*.%s", folderName, fileType)
        local result = {}
        Shared.GetMatchingFileNames(searchPattern, false, result)
        return result
    end

    local filesByFolder = IterableDict()

    for i = 1, #subFolders do

        local folder = subFolders[i]

        for i = 1, #kMAV_FileTypes do
            filesByFolder[folder] = {}
            filesByFolder[folder][kMAV_FileTypes[kMAV_FileTypes[i]]] = GetFilesForFileType(kMAV_FileTypes[i], folder)
        end

    end

    -- Now that we have files by folder, we need to separate them all into their own MAVs
    -- Each folder could have multiple MAVs in them...
    local mavs = {}
    local invalidMavs = {}
    for folder, filesTable in pairs(filesByFolder) do

        -- Validate the interface file, making sure that it is valid JSON, and
        -- make sure the file chain is valid.

        local interfaceFiles = filesTable[kMAV_FileTypes.interface]
        for i = 1, #interfaceFiles do
            local interfaceFilename = interfaceFiles[i]
            local interfaceJson = self:DecodeInterfaceFile(interfaceFilename)
            if interfaceJson then

                if self:ValidateInterface(interfaceJson) then
                    -- TODO(Salads): Create MAV object and add it to mav list
                else
                    -- TODO(Salads): Add error and move on.
                end

            else
                -- TODO(Salads): Add error and move on
            end
        end

    end

end

function MAVManager:ValidateInterface(interface)

    -- When checking errors we just mark as invalid, but don't return early so MAV makers can see all errors at once.
    local isValid = true

    -- Check all root-level json members.
    if type(interface.MAVTitle) ~= "string" or #interface.MAVTitle <= 0 then
        -- TODO(Salads): Add Error
        isValid = false
    end

    if type(interface.ScreenFX) ~= "string" or not GetFileExists(interface.ScreenFX) then
        -- TODO(Salads): Add Error
        isValid = false
    end

    -- "Settings" field isn't required, but if it is filled out we need to validate that as well.
    if MAVGetIsArray(interface.Settings) then
        if not self:ValidateInterfaceSettings(interface.Settings) then
            isValid = false -- ValidateInterfaceSettings will add errors.
        end
    elseif interface.Settings then
        -- TODO(Salads): Add Error
        isValid = false
    end

end

function MAVManager:ValidateInterfaceSettings(settings)

    local allSettingsValid = true

    -- Keep track of these settings, they must be unique across all parameters
    local parameterNames = IterableDict() -- Non-bitfield parameter names
    local guiLabels = IterableDict()
    local bitfieldsToShifts = IterableDict() -- Bitfield names, to arrays of used shifts

    for i = 1, #settings do

        local interfaceSetting = settings[i]
        if type(interfaceSetting) == "table" then

            if type(interfaceSetting.ParameterName) ~= "string" or #interfaceSetting.ParameterName <= 0 then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            end

            if type(interfaceSetting.GUILabel) ~= "string" or #interfaceSetting.GUILabel <= 0 then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            end

            if type(interfaceSetting.DefaultValue) ~= "number" then -- Check ranging later when we know gui type
                allSettingsValid = false
                -- TODO(Salads): Add Error
            end

            if interfaceSetting.Tooltip and (type(interfaceSetting.Tooltip) ~= "string" or #interfaceSetting.Tooltip <= 0) then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            end

            if interfaceSetting.TooltipImage and (type(interfaceSetting.TooltipImage) ~= "string" or not GetFileExists(interfaceSetting.TooltipImage)) then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            end

            if interfaceSetting.BitfieldLShift then -- This parameter is part of a bitfield
                if type(interfaceSetting.BitfieldLShift) ~= "number" then
                    allSettingsValid = false
                    -- TODO(Salads): Add Error
                else

                end
            end

            local guiTypeValid = false
            if type(interfaceSetting.GUIType) ~= "string" then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            elseif kGuiTypes[interfaceSetting.GUIType] == nil then
                allSettingsValid = false
                -- TODO(Salads): Add Error
            else
                guiTypeValid = true
            end

            if guiTypeValid then -- Now that we know gui type and it's valid, now we can check the gui-type specific stuff.

                local guiType = kGuiTypes[interfaceSetting.GUIType]
                if guiType == kGuiTypes.slider then

                elseif guiType == kGuiTypes.dropdown then

                elseif guiType == kGuiTypes.checkbox then

                end

            end

        else
            allSettingsValid = false
            -- TODO(Salads): Add Error
        end

    end

    return allSettingsValid

end

function MAVManager:DecodeInterfaceFile(fileName)

    local interfaceJson
    local interfaceFile = io.open(fileName, "r")
    if interfaceFile then

        local pos, error
        interfaceJson, pos, error = json.decode(interfaceFile:read("*all"))
        if interfaceJson then



        else
            MAVLog("Could not parse interface file '%s' - Error: %s", fileName, error)
        end

    end
end

local MAV
function GetMAV()

    if not MAV then

        MAV = {}
        MAV._FinishedRefreshing = false
        MAV._DefaultDarkVision = nil -- Keep track of the default alien vision.

    end

    return MAV

end

function MAVRefreshAVSources()

    local files = MAVGetModFiles()

    return

    --local avTables = MAVCompileFiles(files)
    --GetMAV()._AVTables = avTables
    --
    --local validAVs, invalidAvs = MAVValidateAVTables(avTables)
    --GetMAV()._ValidAVTables = validAVs
    --GetMAV()._InvalidAVTables = invalidAvs
    --
    --LogErrorsForAVTables(invalidAvs)
    --
    --local guiConfig = MAVGenerateGUIConfigs(validAVs)
    --GetMAV()._GUIConfig = guiConfig
    --
    --table.insert(gModsCategories, guiConfig)
    --
    --Print("$ Finished Refresh of AV Sources")
end
