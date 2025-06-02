LinkLuaModifier("modifier_terrorblade_foulfell_retreat_custom", "heroes/hero_terrorblade/terrorblade_foulfell_retreat_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_terrorblade_foulfell_retreat_custom_buff", "heroes/hero_terrorblade/terrorblade_foulfell_retreat_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_terrorblade_foulfell_retreat_custom_debuff", "heroes/hero_terrorblade/terrorblade_foulfell_retreat_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassdeBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

terrorblade_foulfell_retreat_custom = class(ItemBaseClass)
modifier_terrorblade_foulfell_retreat_custom = class(terrorblade_foulfell_retreat_custom)
modifier_terrorblade_foulfell_retreat_custom_buff = class(ItemBaseClassBuff)
modifier_terrorblade_foulfell_retreat_custom_debuff = class(ItemBaseClassdeBuff)
-------------
function terrorblade_foulfell_retreat_custom:GetIntrinsicModifierName()
    return "modifier_terrorblade_foulfell_retreat_custom"
end

function terrorblade_foulfell_retreat_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_terrorblade_foulfell_retreat_custom_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    EmitSoundOn("Hero_Terrorblade.Reflection", caster)

    local mirreff = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt(
        mirreff,
        0,
        caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( mirreff, 0, caster:GetAbsOrigin() )

    Timers:CreateTimer(1.0, function()
        ParticleManager:DestroyParticle(mirreff, false)
        ParticleManager:ReleaseParticleIndex( mirreff )
    end)
end

function modifier_terrorblade_foulfell_retreat_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetModifierIncomingDamage_Percentage()
    return -100
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_penalty")
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_movespeed")
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetModifierHealthRegenPercentage()
    return self:GetAbility():GetSpecialValueFor("health_regen_pct")
end

function modifier_terrorblade_foulfell_retreat_custom_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
end

function modifier_terrorblade_foulfell_retreat_custom_buff:OnRemoved()
    if not IsServer() then return end
    
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("radius")

    local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_scepter.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        caster,
        PATTACH_ABSORIGIN,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector(radius, radius, radius) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn("Hero_Terrorblade.Metamorphosis.Scepter", caster)

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        victim:AddNewModifier(caster, ability, "modifier_terrorblade_foulfell_retreat_custom_debuff", {
            duration = ability:GetSpecialValueFor("debuff_duration")
        })
    end
end

function modifier_terrorblade_foulfell_retreat_custom_buff:CheckState()
    local state = {
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }

    return state
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf"
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_terrorblade_foulfell_retreat_custom_buff:GetStatusEffectName()
    return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_terrorblade_foulfell_retreat_custom_buff:StatusEffectPriority()
    return 10001
end
---
function modifier_terrorblade_foulfell_retreat_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    }
end

function modifier_terrorblade_foulfell_retreat_custom_debuff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Terrorblade.Metamorphosis.Fear", parent)
end

function modifier_terrorblade_foulfell_retreat_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    if event.attacker == self:GetCaster() then
        return self:GetAbility():GetSpecialValueFor("damage_enemy_increase")
    end
end