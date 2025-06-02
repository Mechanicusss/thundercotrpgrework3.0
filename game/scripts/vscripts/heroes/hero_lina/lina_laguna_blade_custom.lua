LinkLuaModifier("modifier_lina_laguna_blade_custom", "heroes/hero_lina/lina_laguna_blade_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_laguna_blade_custom_debuff", "heroes/hero_lina/lina_laguna_blade_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

lina_laguna_blade_custom = class(ItemBaseClass)
modifier_lina_laguna_blade_custom = class(lina_laguna_blade_custom)
modifier_lina_laguna_blade_custom_debuff = class(ItemBaseClassDebuff)
-------------
function lina_laguna_blade_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    caster:AddNewModifier(target, self, "modifier_lina_laguna_blade_custom", {
        duration = self:GetChannelTime()
    })
end

function lina_laguna_blade_custom:GetChannelTime()
    return 5
end

function lina_laguna_blade_custom:OnChannelFinish()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:RemoveModifierByName("modifier_lina_laguna_blade_custom")
end
--------
function modifier_lina_laguna_blade_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE   
    }
end

function modifier_lina_laguna_blade_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    local caster = self:GetParent()

    if event.attacker ~= caster then return end

    if not caster:HasScepter() then return end

    if not event.inflictor then return end

    if event.inflictor:GetAbilityName() ~= "lina_laguna_blade_custom" then return end

    local increase = self:GetAbility():GetSpecialValueFor("damage_increase_pct") * (self:GetDuration() - self:GetRemainingTime())
    if increase == 0 then return end
    
    return increase
end

function modifier_lina_laguna_blade_custom:OnCreated()
    if not IsServer() then return end

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_lina_laguna_blade_custom:OnIntervalThink()
    local target = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:StartGesture(ACT_DOTA_CAST_ABILITY_4)

    self:PlayEffects(target)

    local damage = ability:GetSpecialValueFor("damage") + (parent:GetBaseIntellect() * (ability:GetSpecialValueFor("int_to_damage")/100))

    local fierySoul = parent:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fierySoul then
        local fierySoul_Ability = fierySoul:GetAbility()

        damage = damage + (fierySoul_Ability:GetSpecialValueFor("fiery_soul_spell_damage") * fierySoul:GetStackCount())
    end

    ApplyDamage({
        attacker = parent,
        victim = target,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        ability = ability
    })

    target:AddNewModifier(parent, ability, "modifier_lina_laguna_blade_custom_debuff", {
        duration = ability:GetSpecialValueFor("debuff_duration")
    })
end

function modifier_lina_laguna_blade_custom:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    parent:RemoveGesture(ACT_DOTA_CAST_ABILITY_4)
end

function modifier_lina_laguna_blade_custom:PlayEffects(target)

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_lina/lina_spell_laguna_blade.vpcf"
    local sound_cast = "Ability.LagunaBladeImpact"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        self:GetParent(),
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end
-----------
function modifier_lina_laguna_blade_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, --GetModifierMagicalResistanceBonus
    }

    return funcs
end

function modifier_lina_laguna_blade_custom_debuff:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end