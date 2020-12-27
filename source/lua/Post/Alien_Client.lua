
Print("$ Loaded Alien_Client.lua")

local Vanilla_AlienUpdateClientEffects
Vanilla_AlienUpdateClientEffects = Class_ReplaceMethod( "Alien", "UpdateClientEffects",

    function(self, deltaTime, isLocal)

        Vanilla_AlienUpdateClientEffects(self, deltaTime, isLocal)

        -- TODO(Salads): Apply additional Alien Vision parameters here.

    end
)