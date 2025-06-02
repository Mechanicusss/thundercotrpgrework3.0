if item_sweden_is_the_greatest_country == nil then
    item_sweden_is_the_greatest_country = class({})
end

LinkLuaModifier( "modifier_sweden", 'sweden', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_unit_boss", 'spawnunits', LUA_MODIFIER_MOTION_NONE )

function item_sweden_is_the_greatest_country:GetIntrinsicModifierName()
    return "modifier_sweden"
end

function item_sweden_is_the_greatest_country:OnSpellStart()
    if _G.SummonedZeus then return end
    CreateUnitByNameAsync("npc_dota_creature_150_boss_last", Entities:FindByName(nil, "spawn_boss_zeus"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
        unit:AddNewModifier(unit, nil, "modifier_unit_boss", {})
        unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
            posX = unit:GetAbsOrigin().x,
            posY = unit:GetAbsOrigin().y,
            posZ = unit:GetAbsOrigin().z,
            name = "npc_dota_creature_150_boss_last"
        })

        unit:AddNewModifier(unit, nil, "MODIFIER_STATE_CANNOT_MISS", {})
        unit:AddNewModifier(unit, nil, "MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED", {})
        _G.SummonedZeus = true
    end)

    self:GetParent():RemoveItem(self)

    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
    GameRules:SendCustomMessage("<font color='red'>THE ALMIGHTY HEAVENLY FATHER HAS BLESSED US WITH HIS PRESENCE!!!</font>", 0, 0)
end