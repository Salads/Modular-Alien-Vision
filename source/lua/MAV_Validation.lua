
Print("$ Loaded MAV_Validation.lua")

Script.Load("lua/MAV_Globals.lua")

function MAVCheckType(value, type)
    return type(value) == type
end

function MAVGetIsArray(test)

    if type(test) ~= "table" then return false end

    local numericalKeys = {}
    for key, value in pairs(test) do

        -- Lua arrays should have a contiguous sequence of numerical keys starting from 1.
        if type(key) ~= "number" then return false end

        -- Lua arrays shouldn't have identical keys.
        if table.contains(numericalKeys) then return false end

        table.insert(numericalKeys, key)

    end

    table.sort(numericalKeys)

    for i = 1, #numericalKeys do
        if i ~= numericalKeys[i] then
            return false
        end
    end

    return true
end

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
--
--        -- 'color' specific options
--        -- No specific options!
--    },
---- And so on...
--]
--}

-- TODO(Salads): Validate the interface.

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

    ---- Validate common required stuff.
    --if not MAVCheckType(interfaceTable.name, "string") then
    --    table.insert(avTable.parameterErrors, "'name' is required, and must be a string!")
    --    isValid = false
    --end
    --
    --if not MAVCheckType(interfaceTable.label, "string") then
    --    table.insert(avTable.parameterErrors, "'label' is required, and must be a string!")
    --    isValid = false
    --end
    --
    --if not MAVCheckType(interfaceTable.default, "number") then
    --    table.insert(avTable.parameterErrors, "'default' is required, and must be a number!")
    --    isValid = false
    --end
    --
    --if not MAVCheckType(interfaceTable.guiType, "string") then
    --    table.insert(avTable.parameterErrors, "'guiType' is required, and must be a string!")
    --    isValid = false
    --elseif not kGuiTypes[interfaceTable.guiType] then
    --    table.insert(avTable.parameterErrors, string.format("'guiType' %s is not a valid type!", interfaceTable.guiType))
    --    isValid = false
    --else
    --
    --end

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
