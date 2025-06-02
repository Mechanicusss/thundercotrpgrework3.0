function OnStartTouch(trigger)
    local player = trigger.activator

    local point = Entities:FindByName(nil, "akasha_tp")

    FindClearSpaceForUnit(player, point:GetAbsOrigin(), false)
end