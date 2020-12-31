
Script.Load("lua/GUI/widgets/GUIButton.lua")
Script.Load("lua/menu2/MenuUtilities.lua")
Script.Load("lua/menu2/MenuStyles.lua")

Script.Load("lua/GUI/wrappers/FXState.lua")

local baseClass = GUIMenuPowerButton
class "GUIMenuErrorsButton" (baseClass)

GUIMenuErrorsButton.kTextureRegular = PrecacheAsset("ui/MAV_Warning.dds")
GUIMenuErrorsButton.kTextureHover = PrecacheAsset("ui/MAV_Warning.dds")

GUIMenuErrorsButton.kWarningIcon = PrecacheAsset("ui/MAV_Warning.dds")
GUIMenuErrorsButton.kNoIssuesIcon = PrecacheAsset("ui/MAV_NoIssues.dds")

---@class GUIMenuErrorsButton : GUIMenuPowerButton
function GUIMenuErrorsButton:Initialize(params, errorDepth)
    errorDepth = (errorDepth or 1) + 1
    baseClass.Initialize(self, params, errorDepth)

    self:SetHasErrors(params.hasErrors or false)

    self:HookEvent(self, "OnPressed", self.OnPressed)
end

function GUIMenuErrorsButton:SetHasErrors(hasErrors)

    if not hasErrors then
        self.graphicName = self.kNoIssuesIcon
    else
        self.graphicName = self.kWarningIcon
    end

    self.normalGraphic:SetTexture(self.graphicName)
    self.normalGraphic:SetSizeFromTexture()

    self.hoverGraphic:SetTexture(self.graphicName)
    self.hoverGraphic:SetSizeFromTexture()
    self.hasErrors = hasErrors

end

function GUIMenuErrorsButton:OnPressed()

    if self.hasErrors then

        -- TODO(Salads): Create widget for showing errors.
        -- TODO(Salads): Open widget for showing errors.

    end

end