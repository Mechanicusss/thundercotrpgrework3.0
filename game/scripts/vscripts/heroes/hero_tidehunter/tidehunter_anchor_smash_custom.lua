LinkLuaModifier("modifier_tidehunter_anchor_smash_custom", "heroes/hero_tidehunter/tidehunter_anchor_smash_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tidehunter_anchor_smash_custom_debuff", "heroes/hero_tidehunter/tidehunter_anchor_smash_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tidehunter_anchor_smash_custom_buff", "heroes/hero_tidehunter/tidehunter_anchor_smash_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

tidehunter_anchor_smash_custom = class(ItemBaseClass)
modifier_tidehunter_anchor_smash_custom = class(tidehunter_anchor_smash_custom)
modifier_tidehunter_anchor_smash_custom_buff = class(ItemBaseClassBuff)
modifier_tidehunter_anchor_smash_custom_debuff = class(ItemBaseClassDebuff)
-------------
function tidehunter_anchor_smash_custom:GetIntrinsicModifierName()
    return "modifier_tidehunter_anchor_smash_custom"
end

function tidehunter_anchor_smash_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tidehunter_anchor_smash_custom:Smash()
    local caster = self:GetCaster()

    EmitSoundOn("Hero_Tidehunter.AnchorSmash", caster)

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(vfx, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("attack_damage")
    local duration = self:GetSpecialValueFor("duration")

    local buff = caster:AddNewModifier(caster, self, "modifier_tidehunter_anchor_smash_custom_buff", {})

    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(),    -- int, your team number
        caster:GetAbsOrigin(), -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius,    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    caster.smash = true

    for _,enemy in ipairs(enemies) do
        if not enemy:IsAlive() then break end 

        caster:PerformAttack(
            enemy,
            true,
            true,
            true,
            false,
            false,
            false,
            true
        )

        enemy:AddNewModifier(caster, self, "modifier_tidehunter_anchor_smash_custom_debuff", {
            duration = duration
        })
    end

    buff:Destroy()

    caster.smash = false
end

function tidehunter_anchor_smash_custom:OnSpellStart()
    if not IsServer() then return end 

    self:Smash()
end
------------
function modifier_tidehunter_anchor_smash_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_tidehunter_anchor_smash_custom:OnCreated()
    if not IsServer() then return end 
end

function modifier_tidehunter_anchor_smash_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    if parent.smash == true then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or not ability:GetAutoCastState() or ability:GetManaCost(-1) > parent:GetMana() or parent:IsSilenced() or parent:IsStunned() or parent:IsHexed() then return end 

    SpellCaster:Cast(ability, parent, true)
end
-----------------------
function modifier_tidehunter_anchor_smash_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_tidehunter_anchor_smash_custom_debuff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_reduction")
end
-----------------------
function modifier_tidehunter_anchor_smash_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_tidehunter_anchor_smash_custom_buff:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("attack_damage")
end

function modifier_tidehunter_anchor_smash_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("attack_damage_pct")
end