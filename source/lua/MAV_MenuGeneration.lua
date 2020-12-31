
Print("$ Loaded MAV_MenuGeneration.lua")

Script.Load("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua")
Script.Load("lua/GUIMenuErrorsButton.lua")
Script.Load("lua/menu2/MenuDataUtils.lua")

-- TODO(Salads): Locale
function MAVGenerateGUIConfigs(avTable)

    -- Create the GUIObjects that will hold all of our MAV related GUIObjects.
    local containerGUIConfig =
    {
        categoryName = "MAVCategory",
        entryConfig =
        {
            name = "MAVEntry",
            class = GUIMenuCategoryDisplayBoxEntry,
            params =
            {
                label = "MAV"
            },
        },

        contentsConfig = ModsMenuUtils.CreateBasicModsMenuContents
        {
            layoutName = "advancedOptions",
            contents = MAVGenerateGUIConfigContents(avTable),
        }
    }

    return containerGUIConfig

end

local function SyncWidthWithPadding(self, size)
    self:SetWidth(size.x - 128)
end

local function SyncWidthToParentContentsWidthWithPadding(self)
    local parentObj = self:GetParent()
    assert(parentObj)
    self:HookEvent(parentObj, "OnContentsSizeChanged", SyncWidthWithPadding)
end

function MAVGenerateGUIConfigContents(avTable)

    return
    {
        -- TODO(Salads): Create MAV top-level controls. (Select AV, Show Errors Button, etc)
        { -- Button to show a window that lists all errors.
            name = "showErrorsButton",
            class = GUIMenuErrorsButton,
            params =
            {
                graphicType = "noissues"
            },
            postInit =
            {
                function(self) self:AlignTop() self:AlignRight() end,
            },

        },
        --{
        --    name = "avPickerDropdown",
        --    class = OP_TT_Choice,
        --    params =
        --    {
        --        optionPath = "MAV/chosenAV",
        --        optionType = "string",
        --        default = "default",
        --        immediateUpdate = function(self)
        --            local oldValue = Client.GetOptionInteger("graphics/display/quality", 1)
        --            local value = self:GetValue()
        --            Client.SetOptionInteger("graphics/display/quality", value)
        --            Client.ReloadGraphicsOptions()
        --
        --            -- Texture settings are loaded on the next frame, so we have to delay the
        --            -- reset by 1 frame.  Do this by creating a timed callback for 0 seconds.
        --            self:AddTimedCallback(
        --                    function(self)
        --                        Client.SetOptionInteger("graphics/display/quality", oldValue)
        --                    end, 0.1)
        --        end,
        --
        --        tooltip = Locale.ResolveString("OPTION_TEXTUREQUALITY"),
        --    },
        --
        --    properties =
        --    {
        --        {"Label", Locale.ResolveString("TEXTURE_QUALITY")..": "},
        --        {"Choices",
        --         {
        --             { value = 0, displayString = Locale.ResolveString("LOW") },
        --             { value = 1, displayString = Locale.ResolveString("MEDIUM") },
        --             { value = 2, displayString = Locale.ResolveString("HIGH") },
        --         },
        --        },
        --    },
        --}

        -- TODO(Salads): Validator for MAV AVs.
        -- TODO(Salads): Create GUIConfig generator for interface files. Have them expandable so we can hide them depending on the selected AV.
    }

end
