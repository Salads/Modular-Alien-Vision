
Script.Load("lua/MAV/MAV_Globals.lua")

function CreateMAVError(errorType, errorMessage)

    local error = MAVError()
    error:SetError(errorType, errorMessage)

    return error

end

class "MAVError"

function MAVError:SetError(errorType, errorMessage)
    self.errorType = errorType
    self.errorMessage = errorMessage
end

function MAVError:GetErrorType()
    return self.errorType
end

function MAVError:GetErrorMessage()
    return self.errorMessage
end