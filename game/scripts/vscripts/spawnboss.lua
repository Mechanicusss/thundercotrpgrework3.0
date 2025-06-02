function SpawnBoss()
    LinkLuaModifier( "nomiss", "modifiers/nomiss", 0 )
    local point = Entities:FindByName( nil, "SB"):GetAbsOrigin()
    local boss = CreateUnitByName("npc_dota_creature_1_crip",point, true, nil, nil, DOTA_TEAM_NEUTRALS)
    boss:AddNewModifier( boss, nil, "nomiss", {} )
end

function BVB()
    local boss = Entities:FindByName( nil, "npc_dota_creature_1_crip")
    boss:AddNewModifier(boss,nil,"MODIFIER_STATE_CANNOT_MISS", {duration = -1})
end