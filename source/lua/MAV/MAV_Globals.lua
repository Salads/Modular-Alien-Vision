
Print("$ Loaded MAV_Globals.lua")

-- These are identifiers that are forbidden due to that member name being used
-- for some other purpose.
kReservedIdentifiers = set
{
    "_skippedFiles" -- For debug information.
}

kMAV_FileTypes = enum(
{
    'interface',
    'hlsl',
    'screenfx',
    'shader'
})

kMAV_ErrorTypes = enum(
{
    'NoError',
    'FileMissing',
    'InterfaceInvalidJson'
})

kGuiTypes = set
{
    "slider",
    "dropdown",
    "checkbox",
    -- "color" -- ScreenFX seems to only have float parameters allowed.
}

kValidStatus = enum(
{
    'Valid',
    'MissingScreenFX',
    'InvalidParameter'
})

kSkippedFileReason = enum(
{
    'UsedReservedId',
    'NoIdentifier'
})