
Print("$ Loaded MAV.lua")

Script.Load("lua/MAV_FileFetch.lua")
Script.Load("lua/MAV_Validation.lua")
Script.Load("lua/MAV_MenuGeneration.lua")
Script.Load("lua/menu2/NavBar/Screens/Options/GUIMenuOptions.lua")

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
    local avTables = MAVCompileFiles(files)
    GetMAV()._AVTables = avTables

    local validAVs, invalidAvs = MAVValidateAVTables(avTables)
    GetMAV()._ValidAVTables = validAVs
    GetMAV()._InvalidAVTables = invalidAvs

    -- TODO(Salads): Generate GUIConfigs for all of the AVs!
    local guiConfig = MAVGenerateGUIConfigs(avTables)
    GetMAV()._GUIConfig = guiConfig

    table.insert(gModsCategories, guiConfig)

end
