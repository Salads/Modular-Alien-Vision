
Print("$ Loaded MAV_Validation.lua")

Script.Load("lua/MAV_Globals.lua")
Script.Load("lua/MAV_Utility.lua")

-- NOTE(Salads): Example JSON Structure for an interface file.
--{ -- Root JSON Object.
--
--    "Parameters" : [
--    { -- Each Parameter is a JSON Object. Here is a description for each member.
--
--        -- All types can use these members. These are required.
--        name = "Parameter Name. ( Will be passed into shader exactly as specified here )",
--        label = "Parameter label, for displaying to the client. (NOT the name of the parameter in-code)",
--        default = "Default value of the parameter.",
--        guiType = "Name of the user control to use for this parameter. ( 'slider', 'dropdown', 'checkbox' )",
--
--        -- OPTIONAL, but if one is specified, all bitfield-related stuff must be for the respective parameter.
--        bitfieldId = "If this is filled out, then this parameter will be set as a 0/1 in a bitfield specified by this variable.",
--        bitfieldIndex = "The bit index that this parameter should set. 20 MAX. (Safe(er?) side of c++ floating point decimal unit capacity)",
--
--        -- OPTIONAL common members.
--        tooltip = "Text that shows up when user is hovering their mouse over the control.",
--        tooltipIcon = "Path to a image to use with the tooltip.",
--
--        -- REQUIRED 'slider' specific options
--        minValue = "Minimum value the slider should allow.",
--        maxValue = "Maximum value the slider should allow.",
--
--        decimalPlaces = "Number of decimal units to include. Ex: 2 = 1.25, 3 = 1.253, etc..", -- OPTIONAL (slider), but 2 by default.
--
--        -- REQUIRED 'dropdown' specific options
--        choices = "A table that specifies the value a dropdown option represents, and the label for that option."
--
--        -- 'checkbox' specific options
--        -- No specific options!
--    },
---- And so on...
--]
--}

local kMAXBitsPerBitfield = 20 -- Could be up to, say, 22 but i'm just cutting it safe.

local kInterfaceDefaults =
{
    decimalPlaces = 0
}

local kOptionalOrRequiredStr =
{
    [true] = "Required",
    [false] = "Optional"
}


local function ValidateInterfaceParameterSetting_String(parameterVar, parameterName, required, errorTable)

    local isValid = true

    if not MAVCheckType(parameterVar, "string") then

        if required or parameterVar ~= nil then
            table.insert(errorTable, string.format("%s setting '%s' must be a string!", kOptionalOrRequiredStr[required], parameterName))
            isValid = false
        end

    elseif parameterVar:len() <= 0 then
        table.insert(errorTable, string.format("%s setting '%s' must be a string with more than 0 characters!", kOptionalOrRequiredStr[required], parameterName))
        isValid = false
    end

    return isValid

end

local function ValidateInterfaceParameterSetting_StringPath(parameterVar, parameterName, required, errorTable)

    local isValid = true

    if not MAVCheckType(parameterVar, "string") then

        if required or parameterVar ~= nil then
            table.insert(errorTable, string.format("%s setting '%s' must be a string file path!", kOptionalOrRequiredStr[required], parameterName))
            isValid = false
        end

    elseif not GetFileExists(parameterVar) then
        table.insert(errorTable, string.format("%s setting '%s' points to a non-existent file! '%s'", kOptionalOrRequiredStr[required], parameterName, parameterVar))
        isValid = false
    end

    return isValid

end

local function ValidateInterfaceParameterSetting_StringSet(parameterVar, parameterName, required, errorTable, constraintSet)

    assert(constraintSet)

    local isValid = true

    if (not MAVCheckType(parameterVar, "string") and (required or parameterVar ~= nil)) or not constraintSet[parameterVar] then
        table.insert(errorTable,
                string.format("%s setting '%s' must be a string matching one of these: ( %s )",
                        kOptionalOrRequiredStr[required],
                        parameterName,
                        GetSetString(kGuiTypes)))

        isValid = false
    end

    return isValid

end

local function ValidateInterfaceParameterSetting_Number(parameterVar, parameterName, required, errorTable)

    local isValid = true

    if not MAVCheckType(parameterVar, "number") then
        if required or parameterVar ~= nil then
            table.insert(errorTable, string.format("%s setting '%s' is required, and must be a number!", kOptionalOrRequiredStr[required], parameterName))
            isValid = false
        end
    end

    return isValid

end

local function ValidateInterfaceParameterGuiType_Slider(parameterTable, avTable)

    -- REQUIRED 'slider' specific options
    -- =======================================================
    -- minValue = "Minimum value the slider should allow.",
    -- maxValue = "Maximum value the slider should allow.",

    -- OPTIONAL
    -- =======================================================
    -- decimalPlaces = "Number of decimal units to include. Ex: 2 = 1.25, 3 = 1.253, and so on.."

    local isValid = true

    -- Validate required options.
    isValid = isValid and ValidateInterfaceParameterSetting_Number(parameterTable.minValue, "minValue", true, avTable.parameterErrors)
    isValid = isValid and ValidateInterfaceParameterSetting_Number(parameterTable.maxValue, "maxValue", true, avTable.parameterErrors)

    -- Make sure that minValue is less than maxValue
    if isValid then
        if (parameterTable.minValue < parameterTable.maxValue) then
            table.insert(avTable.parameterErrors, string.format("minValue must be less than maxValue for 'slider' guiType!"))
            isValid = false
        end
    end

    isValid = isValid and ValidateInterfaceParameterSetting_Number(parameterTable.decimalPlaces or kInterfaceDefaults["decimalPlaces"], "decimalPlaces", false, avTable.parameterErrors)

    return isValid

end

local function ValidateInterfaceParameterGuiType_Dropdown(parameterTable, avTable)

    -- REQUIRED 'dropdown' specific options
    -- ===============================================
    -- choices = "A table that specifies the value a dropdown option represents, and the label for that option."

    -- ...yep, that's the only one! (although we need to check between the values and such, heh

    local isValid = true

    -- Validate the basic structure of the table.
    if not MAVCheckType(parameterTable.choices, "table") then
        table.insert(avTable.parameterErrors, string.format("%s setting '%s' needs to be a array of objects! (Not a table)", kOptionalOrRequiredStr[true], "choices"))
        isValid = false
    end

    if isValid and not MAVGetIsArray(parameterTable.choices) then
        table.insert(avTable.parameterErrors, string.format("%s setting '%s' needs to be a array of objects! (Not a array)", kOptionalOrRequiredStr[true], "choices"))
        isValid = false
    end

    -- Make sure each choices table member is also a table.
    if isValid then

        local invalidChoices_NotTableIndexes = {}
        local invalidChoices_MissingValueIndexes = {}
        local invalidChoices_MissingDisplayStringIndexes = {}
        local invalidChoices_BadValueTypeIndexes = {}
        local invalidChoices_BadDisplayStringTypeIndexes = {}

        local invalidChoices_ValueToChoiceIndexes = {}

        for i = 1, #parameterTable.choices do

            local choiceValid = true

            local choiceTable = parameterTable.choices[i]
            if not MAVCheckType(choiceTable, "table") then
                invalidChoices_NotTableIndexes:insert(i)
                choiceValid = false
            end

            -- Make sure all the choices have the required members filled out.
            if choiceValid then

                if not choiceTable.value then
                    invalidChoices_MissingValueIndexes:insert(i)
                    choiceValid = false
                end

                if not choiceTable.displayString then
                    invalidChoices_MissingDisplayStringIndexes:insert(i)
                    choiceValid = false
                end

            end

            -- Make sure that value and displayString are the correct types.
            if choiceValid then

                if type(choiceTable.value) ~= "number" then
                    invalidChoices_BadValueTypeIndexes:insert(i)
                    choiceValid = false
                end

                if type(choiceTable.displayString) ~= "string" then
                    invalidChoices_BadDisplayStringTypeIndexes:insert(i)
                    choiceValid = false
                end

            end

            -- Record all the values (we've guaranteed that it's a number at this point)
            -- so we can check if there are any copies.
            if choiceValid then
                if not invalidChoices_ValueToChoiceIndexes[choiceTable.value] then
                    invalidChoices_ValueToChoiceIndexes[choiceTable.value] = {}
                end

                invalidChoices_ValueToChoiceIndexes[choiceTable.value]:insert(i)

                if #invalidChoices_ValueToChoiceIndexes[choiceTable.value] > 1 then
                    choiceValid = false
                end
            end

            if not choiceValid then
                isValid = false
            end

        end

        -- Now that we've recorded all the info required for error checking,
        -- add any error messages to our parameter errors table.

        if #invalidChoices_NotTableIndexes > 0 then
            avTable.parameterErrors:insert(string.format("The choices at these indexes are not tables! ( %s )", invalidChoices_NotTableIndexes:to_string()))
        end

        if #invalidChoices_MissingValueIndexes > 0 then
            avTable.parameterErrors:insert(string.format("The choices at these indexes do not have a 'value' member! ( %s )", invalidChoices_MissingValueIndexes:to_string()))
        end

        if #invalidChoices_MissingDisplayStringIndexes > 0 then
            avTable.parameterErrors:insert(string.format("The choices at these indexes do not have a 'displayString' member! ( %s )", invalidChoices_MissingDisplayStringIndexes:to_string()))
        end

        if #invalidChoices_BadValueTypeIndexes > 0 then
            avTable.parameterErrors:insert(string.format("The choices at these indexes have 'value' members that are not numbers! ( %s )", invalidChoices_BadValueTypeIndexes:to_string()))
        end

        if #invalidChoices_BadDisplayStringTypeIndexes > 0 then
            avTable.parameterErrors:insert(string.format("The choices at these indexes have 'displayString' members that are not strings! ( %s )", invalidChoices_BadDisplayStringTypeIndexes:to_string()))
        end

        -- Add errors for re-used value members in the same parameter.
        for _, valueChoiceIndexTable in pairs(invalidChoices_ValueToChoiceIndexes) do

            if #valueChoiceIndexTable > 1 then
                avTable.parameterErrors:insert(string.format("The choices at these indexes have 'value' members that are using the same value! ( %s )",
                        valueChoiceIndexTable:to_string()))
            end

        end

    end

    return isValid

end

local function ValidateInterfaceParameterGuiType_Checkbox(parameterTable, avTable)
    -- There are no specific interface settings for the checkbox!
    return true
end

local kGuiTypeValidators =
{
    ["slider"] = ValidateInterfaceParameterGuiType_Slider,
    ["dropdown"] = ValidateInterfaceParameterGuiType_Dropdown,
    ["checkbox"] = ValidateInterfaceParameterGuiType_Checkbox,
}

function MAVValidateInterface(avTable)

    Print("$ MAVValidateInterface")

    local interfaceTableFilename = avTable.interface
    local interface

    -- decode the interface json file.
    local interfaceFile, errorStr, errorNo = io.open(interfaceTableFilename, "r")
    if interfaceFile then

        local _, error
        interface, _, error = json.decode(interfaceFile:read("*all"))
        io.close(interfaceFile)

        if interface then

            if not interface.Parameters then
                Print(string.format("$ Could not decode interface file '%s' - Error: %s", interfaceTableFilename, error))
                table.insert(avTable.fileSetupErrors, string.format("Could not decode interface file '%s' - Error: %s", interfaceTableFilename, error))
                return false
            end

            if type(interface.Parameters) ~= "table" then
                Print(string.format("$ 'Parameters' member in the interface file must be a JSON array of objects! Input Type: %s", type(interface.Parameters)))
                table.insert(avTable.fileSetupErrors, string.format("'Parameters' member in the interface file must be a JSON array of objects!"))
                return false
            end

            if not MAVGetIsArray(interface.Parameters) then
                Print(string.format("$ 'Parameters' member in the interface file must be a JSON array of objects! (It is not an array!)"))
                table.insert(avTable.fileSetupErrors, string.format("'Parameters' member in the interface file must be a JSON array of objects!"))
                return false
            end

        else
            Print(string.format("$ Could not decode interface file '%s' - Error: %s", interfaceTableFilename, error))
            table.insert(avTable.fileSetupErrors, string.format("Could not decode interface file '%s' - Error: %s", interfaceTableFilename, error))
            return false
        end

    else
        Print(string.format("$ Could not open interface file '%s' - Error: %s (%s)", interfaceTableFilename, errorStr, errorNo))
        table.insert(avTable.fileSetupErrors, string.format("Could not open interface file '%s' - Error: %s (%s)", interfaceTableFilename, errorStr, errorNo))
        return false
    end

    Print("$ Interface file basic structure validated.")

    -- At this point, the interface file exists, and was thrown into the "interface" variable, with the basic structure being validated.
    -- All thats left is to validate each parameter.
    local isValid = true

    local parameterNamesToParameterIndexes = {}
    local bitfieldConflictTable = {}

    if not avTable.parameterErrors then
        avTable.parameterErrors = {}
    end

    for pIndex = 1, #interface.Parameters do

        local parameter = interface.Parameters[pIndex]

        -- Validate common required stuff.
        isValid = isValid and ValidateInterfaceParameterSetting_String(parameter.name, "name", true, avTable.parameterErrors)

        if isValid then

            if not parameterNamesToParameterIndexes[parameter.name] then
                parameterNamesToParameterIndexes[parameter.name] = {}
            end

            parameterNamesToParameterIndexes[parameter.name]:insert(pIndex)

        end

        isValid = isValid and ValidateInterfaceParameterSetting_String(parameter.label, "label", true, avTable.parameterErrors)
        isValid = isValid and ValidateInterfaceParameterSetting_Number(parameter.default, "default", true, avTable.parameterErrors)
        isValid = isValid and ValidateInterfaceParameterSetting_StringSet(parameter.guiType, "guiType", true, avTable.parameterErrors, kGuiTypes)

        -- Validate GUIType specific options.
        if isValid then
            isValid = isValid and kGuiTypeValidators[parameter.guiType](parameter, avTable.parameterErrors)
        end

        -- Validate optional bitfield fields. These have a special relationship, so we can't use the regular generic setting checker.
        -- If one of the bitfield settings are set, then the other must be, or else the whole thing is poopydoodoo.
        local bitfieldIdExists = parameter.bitfieldId ~= nil
        local bitfieldIndexExists = parameter.bitfieldIndex ~= nil

        if (bitfieldIdExists or bitfieldIndexExists) then

            if bitfieldIdExists ~= bitfieldIndexExists then -- poopydoodoo!

                local firstStr = bitfieldIdExists and "bitfieldId" or "bitfieldIndex"
                local secondStr = bitfieldIndexExists and "bitfieldIndex" or "bitfieldId"
                avTable.parameterErrors:insert(string.format("Parameter bitfield setting '%s' is defined, but '%s' isn't!", firstStr, secondStr))
                isValid = false

            else -- Validate both settings, since they both exist.

                local bitfieldsValid = true

                if not MAVCheckType(parameter.bitfieldId, "string") then

                    table.insert(avTable.parameterErrors, string.format("bitfieldId must be a string!"))
                    bitfieldsValid = false

                elseif parameter.bitfieldId:len() <= 0 then

                    table.insert(avTable.parameterErrors, string.format("bitfieldId must be a string with more than 0 characters!"))
                    bitfieldsValid = false

                end

                if not MAVCheckType(parameter.bitfieldIndex, "number") then

                    table.insert(avTable.parameterErrors, string.format("bitfieldId must be a number!"))
                    bitfieldsValid = false

                elseif not (parameter.bitfieldIndex >= 0 and parameter.bitfieldIndex <= kMAXBitsPerBitfield) then

                    table.insert(avTable.parameterErrors, string.format("bitfieldIndex must be a number between 0 and %d (inclusive)!", kMAXBitsPerBitfield))
                    bitfieldsValid = false

                end

                -- If both fields are valid, add them to our conflict tracker table, so that
                -- we can check if different parameters are using the same bitfield index.
                if bitfieldsValid then

                    if not bitfieldConflictTable[parameter.bitfieldId] then
                        bitfieldConflictTable[parameter.bitfieldId] = {}
                    end

                    if not bitfieldConflictTable[parameter.bitfieldId][parameter.bitfieldIndex] then
                        bitfieldConflictTable[parameter.bitfieldId][parameter.bitfieldIndex] = {}
                    end

                    bitfieldConflictTable[parameter.bitfieldId][parameter.bitfieldIndex]:insert(pIndex)

                end

                isValid = isValid and bitfieldsValid

            end

        end

        isValid = isValid and ValidateInterfaceParameterSetting_String(parameter.tooltip, "tooltip", false, avTable.parameterErrors)
        isValid = isValid and ValidateInterfaceParameterSetting_StringPath(parameter.tooltipIcon, "tooltipIcon", false, avTable.parameterErrors)
    end

    -- TODO(Salads): Check for bitfield conflicts between parameters.

    return isValid

end

function MAVValidateAVTables(avTables)

    local validAVs = {}
    local invalidAVs = {}

    -- Validate file-level stuff.
    for identifier, avTable in pairs(avTables) do

        if not kReservedIdentifiers[identifier] then

            local valid = true

            -- screenfx file is always required, as it's used to create the effect.
            -- If this is missing, then the rest is futile.
            if not avTable.screenfx then
                table.insert(avTable.fileSetupErrors, "Missing screenfx file! All AVs need this file at a minimum!")
                valid = false
            end

            -- Verify that the screenfx file points to a valid shader source, and that shader's source points to a valid hlsl source.
            -- Engine will log an error anyways, but it'd be nice to see this more easily, plus it'd help determine if the av is valid.

            local fileScreenFx, errorStr, errorNo
            if valid then
                -- Check screenfx file for a valid source.
                fileScreenFx, errorStr, errorNo = io.open(avTable.screenfx, "r")
                if not fileScreenFx then
                    table.insert(avTable.fileSetupErrors, string.format("Could not open screenfx file! Error: %s (%s)", errorStr, errorNo))
                    valid = false
                end
            end

            local shaderSource
            if valid then
                local screenFXText = fileScreenFx:read("*all")
                io.close(fileScreenFx)

                shaderSource = screenFXText:match'shader[%s]*=[%s]*"[^"]+"'
                if not shaderSource then
                    table.insert(avTable.fileSetupErrors, string.format("screenfx file does not have a shader source specified!"))
                    valid = false
                end
            end

            local shaderSourceValue
            if valid then
                Log("$ Found shader source! %s", shaderSource)
                shaderSourceValue = shaderSource:match'"[^"]*"'
                if not shaderSourceValue then
                    table.insert(avTable.fileSetupErrors, string.format("screenfx file does not have a valid shader source specified!"))
                    valid = false
                end
            end

            local shaderSourcePath
            if valid then
                Log("$ Found shader source value! %s", shaderSourceValue)
                shaderSourcePath = shaderSourceValue:gsub("\"", "") -- remove quotes
                Log("$ Shader Source Path: %s - Exists: %s", shaderSourcePath, GetFileExists(shaderSourcePath))
                if not GetFileExists(shaderSourcePath) then
                    table.insert(avTable.fileSetupErrors, string.format("screenfx file shader source file '%s'! does not exist!", shaderSourcePath))
                    valid = false
                end
            end

            -- Check shader file source for valid code source.
            local fileShader, shaderErrorStr, shaderErrorNo
            if valid then
                Log("$ Shader Source %s exists!", shaderSourcePath)
                fileShader, shaderErrorStr, shaderErrorNo = io.open(shaderSourcePath, "r")
                if not fileShader then
                    table.insert(avTable.fileSetupErrors, string.format("Could not open shader file! Error: %s (%s)", shaderErrorStr, shaderErrorNo))
                    valid = false
                end
            end

            local shaderCodeSource
            if valid then

                local shaderFileText = fileShader:read("*all")
                io.close(fileShader)

                shaderCodeSource = shaderFileText:match'source[%s]*=[%s]*"[^"]+"'
                if not shaderCodeSource then
                    table.insert(avTable.fileSetupErrors, string.format("shader file does not have a valid shader source specified!"))
                    valid = false
                end
            end

            local shaderCodeSourceValue
            if valid then
                shaderCodeSourceValue = shaderCodeSource:match'"[^"]*"'
                if not shaderCodeSourceValue then
                    table.insert(avTable.fileSetupErrors, string.format("shader file does not have a shader source specified!"))
                    valid = false
                end
            end

            if valid then
                local shaderCodeSourcePath = shaderCodeSourceValue:gsub("\"", "")
                Log("$ Shader Code Source: '%s' Exists: %s", shaderCodeSourcePath, GetFileExists(shaderCodeSourcePath))
                if not GetFileExists(shaderCodeSourcePath) then
                    table.insert(avTable.fileSetupErrors, string.format("shader file specified code file '%s'! does not exist!", shaderCodeSourcePath))
                    valid = false
                end
            end

            if valid then

                local interfaceValid = true
                if avTable.interface then
                    interfaceValid = MAVValidateInterface(avTable)
                end

                -- If a AV has a interface specified, then that must be valid too.
                valid = valid and interfaceValid
            end

            if valid then
                table.insert(validAVs, avTable)
                Log("$ Added '%s' to Valid AVs", avTable.id)
            else
                table.insert(invalidAVs, avTable)
                Log("$ Added '%s' to Invalid AVs", avTable.id)
            end

        end

    end

    return validAVs, invalidAVs

end
