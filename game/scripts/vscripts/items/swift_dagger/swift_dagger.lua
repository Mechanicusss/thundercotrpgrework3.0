LinkLuaModifier("modifier_item_swift_dagger", "items/swift_dagger/swift_dagger", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_swift_dagger_active", "items/swift_dagger/swift_dagger", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}


item_swift_dagger = class(ItemBaseClass)
item_swift_dagger_2 = item_swift_dagger
item_swift_dagger_3 = item_swift_dagger
item_swift_dagger_4 = item_swift_dagger
item_swift_dagger_5 = item_swift_dagger
modifier_item_swift_dagger = class(ItemBaseClass)
modifier_item_swift_dagger_active = class(ItemBaseClassActive)
-------------
function item_swift_dagger:GetIntrinsicModifierName()
    return "modifier_item_swift_dagger"
end

function item_swift_dagger:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    caster:AddNewModifier(caster, ability, "modifier_item_swift_dagger_active", { duration = duration })
end
---
function modifier_item_swift_dagger:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, --GetModifierBonusStats_Strength
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, --GetModifierBonusStats_Agility
        MODIFIER_PROPERTY_STATUS_RESISTANCE, --GetModifierStatusResistance
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
    }

    return funcs
end



function modifier_item_swift_dagger:GetModifierBonusStats_Strength()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_strength", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierBonusStats_Agility()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_agility", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierStatusResistance()
    return self:GetAbility():GetLevelSpecialValueFor("status_resistance", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetLevelSpecialValueFor("bonus_attack_speed", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("movement_speed_percent_bonus", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("hp_regen_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_item_swift_dagger:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("hp_regen_amp", (self:GetAbility():GetLevel() - 1))
end
--

function modifier_item_swift_dagger:OnCreated()
    if not IsServer() then return end

    --self:StartIntervalThink(0.1)
end

function modifier_item_swift_dagger:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_AGILITY and caster:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_STRENGTH then
        caster:DropItemAtPositionImmediate(self:GetAbility(), caster:GetAbsOrigin())
        DisplayError(caster:GetPlayerID(), "Only Agility and Strength heroes can use this item.")
    end

    self:StartIntervalThink(-1)
end
---
function modifier_item_swift_dagger_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, --GetModifierIncomingDamage_Percentage
        
    }

    return funcs
end

function modifier_item_swift_dagger_active:GetModifierMoveSpeedBonus_Percentage()
    return 100
end

function modifier_item_swift_dagger_active:GetModifierIncomingDamage_Percentage(event)
    if self:GetParent() ~= event.target then return end

    return -100
end

function modifier_item_swift_dagger_active:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_faceless_void/faceless_void_backtrack.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CENTER_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_CENTER_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 1, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end

function modifier_item_swift_dagger_active:OnCreated(params)
    if IsServer() then 
        self:StartIntervalThink(0.3) 
        return 
    end
end

function modifier_item_swift_dagger_active:OnIntervalThink()
    self:PlayEffects(self:GetParent())
end
---