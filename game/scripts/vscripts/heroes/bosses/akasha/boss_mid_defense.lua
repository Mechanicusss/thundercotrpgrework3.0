LinkLuaModifier("boss_mid_defense", "heroes/bosses/akasha/boss_mid_defense", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("boss_mid_defense_modifier", "heroes/bosses/akasha/boss_mid_defense", LUA_MODIFIER_MOTION_NONE)

local Baseclass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
}

boss_mid_defense = class(Baseclass)
boss_mid_defense_modifier = class(Baseclass)

DEFENSE_STATUS_RESISTANCE = 75 -- Percent
DEFENSE_MAGIC_RESISTANCE = 95 -- Percent

BANNED_MODIFIERS = {
    "modifier_abyssal_underlord_firestorm_tinker",
    "modifier_abyssal_underlord_firestorm_burn",
    "modifier_necrolyte_reapers_scythe",
    "modifier_juggernaut_omnislash",
    "modifier_juggernaut_omnislash_invulnerability",
    "modifier_batrider_flaming_lasso",
    "modifier_ursa_fury_swipes_damage_increase",
    "modifier_item_hurricane_pike_active",
    "modifier_item_forcestaff_active",
    "modifier_huskar_burning_spear_counter",
    "modifier_huskar_burning_spear_debuff"
}

function boss_mid_defense:GetIntrinsicModifierName()
    return "boss_mid_defense_modifier"
end

function boss_mid_defense:OnCreated()
    local boss = self:GetParent()

    boss:AddNewModifier(boss, nil, "boss_mid_defense_modifier", {})
    boss:AddNewModifier(boss, nil, "modifier_item_gem_of_true_sight", {})
end

function boss_mid_defense_modifier:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        --MODIFIER_PROPERTY_STATUS_RESISTANCE,
        --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
        --MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
    }

    return funcs
end

function boss_mid_defense_modifier:GetModifierIgnoreMovespeedLimit()
    return 1
end

function boss_mid_defense_modifier:GetModifierMoveSpeed_Limit()
    return 2000
end

function boss_mid_defense_modifier:GetModifierProvidesFOWVision()
    return 1
end

function boss_mid_defense_modifier:OnCreated()
    if not IsServer() then
        return
    end
    
    self.unit = self:GetParent()

    self:StartIntervalThink(0.5)
end

function boss_mid_defense_modifier:OnIntervalThink()
    local units = FindUnitsInRadius(self.unit:GetTeam(), self.unit:GetAbsOrigin(), nil,
            600, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER, false)

    for _,unit in ipairs(units) do
        if unit:HasModifier("modifier_phantom_assassin_blur_active") then
            unit:RemoveModifierByName("modifier_phantom_assassin_blur_active")
        end
    end

    for _,mod in ipairs(BANNED_MODIFIERS) do
        if self.unit:HasModifier(mod) then
            self.unit:RemoveModifierByName(mod)
        end
    end

    --self.unit:Purge(false, true, false, true, true)
end

function boss_mid_defense_modifier:GetModifierIncomingDamage_Percentage()
    if self:GetParent():GetAttackCapability() == DOTA_UNIT_CAP_NO_ATTACK then
        return -100
    end

    return 100
end

function boss_mid_defense_modifier:GetModifierStatusResistance()
    return DEFENSE_STATUS_RESISTANCE
end

function boss_mid_defense_modifier:GetModifierMagicalResistanceBonus()
    return DEFENSE_MAGIC_RESISTANCE
end

function boss_mid_defense_modifier:GetPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function boss_mid_defense_modifier:CheckState()
    local state = {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = false,
        [MODIFIER_STATE_CANNOT_MISS] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_PASSIVES_DISABLED] = false
    }

    return state
end