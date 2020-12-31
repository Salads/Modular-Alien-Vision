
Print("$ Loaded MAV_Validation.lua")

Script.Load("lua/MAV_Globals.lua")

function MAVCheckType(value, type)
    return type(value) == type
end

-- NOTE(Salads): Example JSON Structure for an interface file.
--[[

    { -- Root JSON Object.

          "Parameters" : [
                            { -- Each Parameter is a JSON Object. Here is a description for each member.

                                -- All types can use these members. These are required.
                                name = "Parameter Name. ( Will be passed into shader exactly as specified here )",
                                label = "Parameter label, for displaying to the client. (NOT the name of the parameter in-code)",
                                default = "Default value of the parameter.",
                                guiType = "Name of the user control to use for this parameter. ( 'slider', 'dropdown', 'checkbox', 'color' )",

                                -- OPTIONAL, but if one is specified, all bitfield-related stuff must be for the respective parameter.
                                bitfieldId = "If this is filled out, then this parameter will be set as a 0/1 in a bitfield specified by this variable.",
                                bitfieldIndex = "The bit index that this parameter should set. 20 MAX. (Safe(er?) side of c++ floating point decimal unit capacity)",

                                -- OPTIONAL common members.
                                tooltip = "Text that shows up when user is hovering their mouse over the control.",
                                tooltipIcon = "Path to a image to use with the tooltip.",

                                -- REQUIRED 'slider' specific options
                                minValue = "Minimum value the slider should allow.",
                                maxValue = "Maximum value the slider should allow.",

                                decimalPlaces = "Number of decimal units to include. Ex: 2 = 1.25, 3 = 1.253, etc..", -- OPTIONAL (slider), but 2 by default.

                                -- REQUIRED 'dropdown' specific options
                                choices = "A table that specifies the value a dropdown option represents, and the label for that option."

                                -- 'checkbox' specific options
                                -- No specific options!

                                -- 'color' specific options
                                -- No specific options!
                            },
                            -- And so on...
                         ]
      }

--]]
-- TODO(Salads): Validate the interface.
function MAVValidateInterface(avTable)

    local interfaceTable = avTable.interface
    local isValid = true

    -- Validate common required stuff.
    if not MAVCheckType(interfaceTable.name, "string") then
        table.insert(avTable.parameterErrors, "'name' is required, and must be a string!")
        isValid = false
    end

    if not MAVCheckType(interfaceTable.label, "string") then
        table.insert(avTable.parameterErrors, "'label' is required, and must be a string!")
        isValid = false
    end

    if not MAVCheckType(interfaceTable.default, "number") then
        table.insert(avTable.parameterErrors, "'default' is required, and must be a number!")
        isValid = false
    end

    if not MAVCheckType(interfaceTable.guiType, "string") then
        table.insert(avTable.parameterErrors, "'guiType' is required, and must be a string!")
        isValid = false
    elseif not kGuiTypes[interfaceTable.guiType] then
        table.insert(avTable.parameterErrors, string.format("'guiType' %s is not a valid type!", interfaceTable.guiType))
        isValid = false
    else

    end

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
            else

                -- Verify that the screenfx file points to a valid shader source, and that shader's source points to a valid hlsl source.
                -- Engine will log an error anyways, but it'd be nice to see this more easily, plus it'd help determine if the av is valid.

                -- Check screenfx file for a valid source.
                local fileScreenFx, errorStr, errorNo = io.open(avTable.screenfx, "r")
                if fileScreenFx then

                    local screenFXText = fileScreenFx:read("*all")
                    io.close(fileScreenFx)

                    local shaderSource = screenFXText:match'shader[%s]*=[%s]*"[^"]+"'
                    if shaderSource then

                        Log("$ Found shader source! %s", shaderSource)
                        local shaderSourceValue = shaderSource:match'"[^"]*"'
                        if shaderSourceValue then

                            Log("$ Found shader source value! %s", shaderSourceValue)
                            local shaderSourcePath = shaderSourceValue:gsub("\"", "") -- remove quotes
                            if GetFileExists(shaderSourcePath) then

                                -- Check shader file source for valid code source.
                                Log("$ Shader Source %s exists!", shaderSourcePath)
                                local fileShader, shaderErrorStr, shaderErrorNo = io.open(shaderSourcePath, "r")
                                if fileShader then

                                    local shaderFileText = fileShader:read("*all")
                                    io.close(fileShader)

                                    local shaderCodeSource = shaderFileText:match'source[%s]*=[%s]*"[^"]+"'
                                    if shaderCodeSource then

                                        Log("$ Shader Code Source: %s", shaderCodeSource)
                                        local shaderCodeSourcePath = shaderCodeSource:gsub("\"", "")
                                        if GetFileExists(shaderCodeSourcePath) then

                                            -- Done validating file-level stuff!
                                            valid = true

                                        else
                                            table.insert(avTable.fileSetupErrors, string.format("shader file specified code file '%s'! does not exist!", shaderCodeSourcePath))
                                            valid = false
                                        end
                                    else
                                        table.insert(avTable.fileSetupErrors, string.format("shader file does not have a shader source specified!"))
                                        valid = false
                                    end
                                else
                                    table.insert(avTable.fileSetupErrors, string.format("Could not open shader file! Error: %s (%s)", shaderErrorStr, shaderErrorNo))
                                    valid = false
                                end
                            else
                                table.insert(avTable.fileSetupErrors, string.format("screenfx file shader source file '%s'! does not exist!", shaderSourcePath))
                                valid = false
                            end
                        else
                            table.insert(avTable.fileSetupErrors, string.format("screenfx file does not have a valid shader source specified!"))
                            valid = false
                        end
                    else
                        table.insert(avTable.fileSetupErrors, string.format("screenfx file does not have a shader source specified!"))
                        valid = false
                    end
                else
                    table.insert(avTable.fileSetupErrors, string.format("Could not open screenfx file! Error: %s (%s)", errorStr, errorNo))
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
            else
                table.insert(invalidAVs, avTable)
            end
        end
    end

    return validAVs, invalidAVs

end
