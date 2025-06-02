function UseGoldBag(keys)
    local Caster = keys.caster
    local ability = keys.ability

    if not Caster:IsRealHero() then
        return
    end

    local randomCount = RandomInt(1, 10)

    local gold = RandomInt(100, 1000)
    local gameTime = math.floor(GameRules:GetGameTime() / 60)
    gold = gold * (gameTime/8) * 0.35

    local allies = FindUnitsInRadius(Caster:GetTeam(), Caster:GetAbsOrigin(), nil,
            600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,ally in ipairs(allies) do
        if not ally:IsAlive() or not ally:IsRealHero() or ally:IsIllusion() or ally:IsTempestDouble() then break end

        ally:ModifyGoldFiltered(gold, true, DOTA_ModifyGold_NeutralKill) 

        local midas_particle = ParticleManager:CreateParticle("particles/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_midas_coinshower.vpcf", PATTACH_OVERHEAD_FOLLOW, ally)   
        ParticleManager:SetParticleControlEnt(midas_particle, 0, ally, PATTACH_POINT_FOLLOW, "attach_hitloc", ally:GetAbsOrigin(), false)
        ParticleManager:ReleaseParticleIndex(midas_particle)
        ally:EmitSound("DOTA_Item.Hand_Of_Midas")
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, ally, gold, nil)
    end

    Caster:RemoveItem(ability)
end