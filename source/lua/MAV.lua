
Print("$ Loaded MAV.lua")

Script.Load("lua/MAV_FileFetch.lua")

local MAV
function GetMAV()

    if not MAV then

        MAV = {}
        MAV._FinishedRefreshing = false
        MAV._DefaultDarkVision = nil -- Keep track of the default alien vision.

    end

    return MAV

end

local function OnLoadComplete()
    MAVRefreshAVSources()
end
Event.Hook("LoadComplete", OnLoadComplete)