
Print("$ Loaded MAV_GUIGenerators.lua")

local function GenerateInterface_Dropdown(avId, interfaceData)

    return
    {
        name = string.format("mavGUI_%s", interfaceData.name),
        class = OP_TT_Choice,
        params =
        {
            optionType = "float",
            optionPath = string.format("MAV/%s/%s", avId, interfaceData.name),
            default = interfaceData.default,

            tooltip = interfaceData.tooltip,
            tooltipIcon = interfaceData.tooltipIcon
        },

        properties =
        {
            {"Label", interfaceData.label},
            {"Choices", interfaceData.choices},
        },

        postInit = function(self)
            --self:AlignCenter()
        end
    }

end

local function GenerateInterface_Slider(avId, interfaceData)

    return
    {
        name = string.format("mavGUI_%s", interfaceData.name),
        class = OP_TT_Number,
        params =
        {
            optionType = "float",
            optionPath = string.format("MAV/%s/%s", avId, interfaceData.name),
            default = interfaceData.default,

            minValue = interfaceData.minValue,
            maxValue = interfaceData.maxValue,
            decimalPlaces = interfaceData.decimalPlaces,

            label = interfaceData.label,

            tooltip = interfaceData.tooltip,
            tooltipIcon = interfaceData.tooltipIcon
        },

        postInit = function(self)
            --self:AlignCenter()
        end
    }

end

local function GenerateInterface_Checkbox(avId, interfaceData)

    return
    {
        name = string.format("mavGUI_%s", interfaceData.name),
        class = OP_TT_Checkbox,
        params =
        {
            optionType = "bool",
            optionPath = string.format("MAV/%s/%s", avId, interfaceData.name),
            default = interfaceData.default,

            label = interfaceData.label,

            tooltip = interfaceData.tooltip,
            tooltipIcon = interfaceData.tooltipIcon
        },

        postInit = function(self)
            --self:AlignCenter()
        end
    }

end

local kGenerators =
{
    ["slider"] = GenerateInterface_Slider,
    ["checkbox"] = GenerateInterface_Checkbox,
    ["dropdown"] = GenerateInterface_Dropdown,
}

function MAV_GenerateGUIConfigForParameter(avId, interfaceData)

    local generator = kGenerators[interfaceData.guiType]
    assert(generator)

    return generator(avId, interfaceData)

end
