
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

local function GetAVChoices(avTable)

    local choicesTable = {}

    -- default option.
    table.insert(choicesTable, { value = "default", displayString = "Default" })

    for i = 1, #avTable do
        table.insert(choicesTable, { value = avTable[i].id, displayString = avTable[i].id })
    end

    return choicesTable

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
        {
            name = "mav_avPickDropdown",
            class = OP_TT_Choice,
            params =
            {
                optionPath = "MAV/avChoice",
                optionType = "string",
                default = "default",
                immediateUpdate = function(self)
                end,

                tooltip = "Choose your Alien Vision",
            },

            properties =
            {
                {"Label", "Alien Vision: "},
                {"Choices", GetAVChoices(avTable) },
            },
        }

        -- TODO(Salads): Create GUIConfig generator for interface files. Have them expandable so we can hide them depending on the selected AV.
    }

end
