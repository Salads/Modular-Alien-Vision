
Print("$ Loaded MAV_Filehooks.lua")

--ModLoader.SetupFileHook("lua/Alien_Client.lua", "lua/Post/Alien_Client.lua", "post") -- For real-time updates, gonna forego it for now.
ModLoader.SetupFileHook("lua/Player_Client.lua", "lua/Post/Player_Client.lua", "post") -- Hook the default alien vision.

-- Adds MAV mod menu category.
ModLoader.SetupFileHook("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua", "lua/Post/ModsMenuData.lua", "post")
