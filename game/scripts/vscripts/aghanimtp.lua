function OnStartTouch(trigger)
    local player = trigger.activator

    local point = Entities:FindByName(nil, "aghanim_tp")

    EmitSoundOn("TwinGate.Channel", player)

    FindClearSpaceForUnit(player, point:GetAbsOrigin(), false)
end