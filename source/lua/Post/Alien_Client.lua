
Print("$ Loaded Alien_Client.lua")

local Vanilla_AlienUpdateClientEffects
Vanilla_AlienUpdateClientEffects = Class_ReplaceMethod( "Alien", "UpdateClientEffects",

    function(self, deltaTime, isLocal)

        Vanilla_AlienUpdateClientEffects(self, deltaTime, isLocal)

        -- FUTURE(Salads): Apply additional Alien Vision parameters here. (Real-Time AV Settings)

    end
)