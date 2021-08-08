
Print("$ Loaded Player_Client.lua")

Script.Load("lua/MAVManager.lua")

-- Save the default screen effect for alien vision right after the file is loaded.
-- NOTE(Salads): If an AV mod is loaded that simply replaces the default shader file(s), the default MAV option will be that mod. (It was loaded before MAV)
GetMAV()._DefaultDarkVision = Player.screenEffects.darkVision

