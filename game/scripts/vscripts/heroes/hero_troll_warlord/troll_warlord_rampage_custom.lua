LinkLuaModifier("modifier_troll_warlord_rampage_custom", "heroes/hero_troll_warlord/troll_warlord_rampage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_rampage_custom_buff", "heroes/hero_troll_warlord/troll_warlord_rampage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_warlord_rampage_custom_debuff", "heroes/hero_troll_warlord/troll_warlord_rampage_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

troll_warlord_rampage_custom = class(ItemBaseClass)
modifier_troll_warlord_rampage_custom = class(troll_warlord_rampage_custom)
modifier_troll_warlord_rampage_custom_buff = class(ItemBaseClassBuff)
modifier_troll_warlord_rampage_custom_debuff = class(ItemBaseClassDebuff)
-------------
function troll_warlord_rampage_custom:GetIntrinsicModifierName()
    return "modifier_troll_warlord_rampage_custom"
end

function troll_warlord_rampage_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    caster:AddNewModifier(caster, self, "modifier_troll_warlord_rampage_custom_buff", {
        duration = duration
    })

    EmitSoundOn("Hero_TrollWarlord.Rampage.Cast", caster)

    local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_troll_warlord/troll_warlord_rampage.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl(particle, 0, caster:GetOrigin())
    ParticleManager:ReleaseParticleIndex(particle)

    local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemies) do
        enemy:AddNewModifier(caster, self, "modifier_troll_warlord_rampage_custom_debuff", {
            duration = duration
        })

        enemy:AddNewModifier(caster, nil, "modifier_stunned", {
            duration = self:GetSpecialValueFor("stun_duration")
        })

        ApplyDamage({
            attacker = caster,
            victim = enemy,
            damage = self:GetSpecialValueFor("damage") + (caster:GetAgility()*(self:GetSpecialValueFor("agi_to_damage")/100)),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self,
        })
    end
end
---------------------
function modifier_troll_warlord_rampage_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
    return funcs
end

function modifier_troll_warlord_rampage_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    
    self.particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_troll_warlord/troll_warlord_rampage_attack_speed_buff.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, parent:GetOrigin())
end

function modifier_troll_warlord_rampage_custom_buff:OnRemoved()
    if not IsServer() then return end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_troll_warlord_rampage_custom_buff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end


function modifier_troll_warlord_rampage_custom_buff:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage")
end

function modifier_troll_warlord_rampage_custom_buff:GetModifierEvasion_Constant()
    if self:GetParent():HasModifier("modifier_item_aghanims_shard") then
        return self:GetAbility():GetSpecialValueFor("bonus_evasion")
    end
end
---
function modifier_troll_warlord_rampage_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }

    return funcs
end

function modifier_troll_warlord_rampage_custom_debuff:GetModifierDamageOutgoing_Percentage()
    return self.reduction
end

function modifier_troll_warlord_rampage_custom_debuff:OnCreated()
    local parent = self:GetParent()

    self.reduction = self:GetAbility():GetSpecialValueFor("attack_reduction")

    if not IsServer() then return end
    
    self.particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_troll_warlord/troll_warlord_rampage_resistance_buff.vpcf", PATTACH_POINT_FOLLOW, parent )
    ParticleManager:SetParticleControl(self.particle, 0, parent:GetOrigin())
    ParticleManager:SetParticleControl(self.particle, 1, parent:GetOrigin())
end

function modifier_troll_warlord_rampage_custom_debuff:OnRemoved()
    if not IsServer() then return end

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end