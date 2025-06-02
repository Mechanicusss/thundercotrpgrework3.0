local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_summoning_scroll_slark = class(ItemBaseClass)

BOSS_NAME = "npc_dota_creature_80_boss"
-------------
function item_summoning_scroll_slark:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    if caster:GetLevel() < 100 then
        DisplayError(caster:GetPlayerID(), "Level Too Low To Summon. Requires Level " .. 100 .. ".")

        caster:Stop()
        self:EndCooldown()
        return
    end

    -- Check if player is in the fountain --
    if caster:HasModifier("modifier_fountain_aura_buff") or caster:HasModifier("modifier_fountain_invulnerability") then
        DisplayError(caster:GetPlayerID(), "Cannot Summon Inside Fountain.")

        caster:Stop()
        self:EndCooldown()
        return
    end

    -- Check if player is inside the summoning zone --
    local summoningZone = Entities:FindByNameWithin(nil, "trigger_boss_summon_loc", caster:GetAbsOrigin(), caster:Script_GetAttackRange())
    if summoningZone == nil or (summoningZone ~= nil and not IsInTrigger(caster, summoningZone)) then
        DisplayError(caster:GetPlayerID(), "Must Summon Inside The Summoning Pit.")

        local pingZone = Entities:FindAllByName("trigger_boss_summon_loc")
        for _,pz in ipairs(pingZone) do
            GameRules:ExecuteTeamPing(caster:GetTeamNumber(), pz:GetAbsOrigin().x, pz:GetAbsOrigin().y, caster, 0)
        end

        caster:Stop()
        self:EndCooldown()
        return
    end

    -- Check if any bosses are inside the summoning zone --
    local canFindBoss = false
    local existingBosses = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        caster:Script_GetAttackRange(), DOTA_TEAM_NEUTRALS, bit.bor(DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,boss in ipairs(existingBosses) do
        if boss:GetUnitName() == BOSS_NAME then
            canFindBoss = true
            break
        end
    end

    if canFindBoss then
        DisplayError(caster:GetPlayerID(), "Summon Is Already Active.")

        caster:Stop()
        self:EndCooldown()
        return
    end

    CreateUnitByNameAsync(BOSS_NAME, caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS, function(unit)
        --Async is faster and will help reduce stutter
        unit:AddNewModifier(unit, nil, "modifier_unit_boss_2", {})
        unit:AddNewModifier(unit, nil, "MODIFIER_STATE_CANNOT_MISS", {})
        unit:AddNewModifier(unit, nil, "MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED", {})

        unit:AddNewModifier(unit, nil, "modifier_unit_on_death", {
            posX = unit:GetAbsOrigin().x,
            posY = unit:GetAbsOrigin().y,
            posZ = unit:GetAbsOrigin().z,
            name = BOSS_NAME
        })
    end)

    self:Destroy()
end