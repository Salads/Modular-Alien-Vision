
Print("$ Loaded MAV_MenuGeneration.lua")

Script.Load("lua/menu2/NavBar/Screens/Options/Mods/ModsMenuData.lua")
Script.Load("lua/GUIMenuErrorsButton.lua")
Script.Load("lua/menu2/MenuDataUtils.lua")
Script.Load("lua/GUI/wrappers/WrapperUtility.lua")
Script.Load("lua/MAV_GUIGenerators.lua")

-- TODO(Salads): Locale
function MAVGenerateGUIConfigs(avTables)

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
            contents = MAVGenerateGUIConfigContents(avTables),
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

function MAVGenerateGUIConfigContents(avTables)

    local avGUIConfigs =
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
                function(self) self:AlignTop() self:AlignLeft() end,
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

                toolTip = "Choose your Alien Vision",
            },

            properties =
            {
                {"Label", "Alien Vision: "},
                {"Choices", GetAVChoices(avTables) },
            },

            postInit =
            {
                function(self) self:AlignCenter() end,
            }
        },
        {
            name = "avDivider",
            class = GUIMenuDividerWidget,

            properties =
            {
                {"Label", "=== AV-Specific Options ==="}
            },

            postInit =
            {
                function(self) self:AlignCenter() end,
            }
        }

    }

    for i = 1, #avTables do
        table.insert(avGUIConfigs, GetGUIConfigForAV(avTables[i]))
    end

    return avGUIConfigs

end

ExpandableGUIListLayout = GetMultiWrappedClass(GUIListLayout, {"Expandable"})

function GetGUIConfigForAV(avTable)

    return
    {
        name = string.format("mav_%s_rootExpandableListLayout", avTable.id),
        class = ExpandableGUIListLayout,
        params =
        {
            orientation = "vertical",
            expanded = true
        },
        properties =
        {
            {"FrontPadding", 0},
            {"BackPadding", 0},
            {"Spacing", 32},
        },

        children = GetGUIConfigForAVInterface(avTable),

        postInit = function(self)
            self:AlignCenter()
        end
    }

end

function GetGUIConfigForAVInterface(avTable)

    local avParameterGUIConfigs = {}

    for i = 1, #avTable.interfaceData.Parameters do
        table.insert(avParameterGUIConfigs, MAV_GenerateGUIConfigForParameter(avTable.id, avTable.interfaceData.Parameters[i]))
    end

    return avParameterGUIConfigs

end
