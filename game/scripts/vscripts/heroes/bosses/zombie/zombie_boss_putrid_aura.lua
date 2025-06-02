LinkLuaModifier("modifier_zombie_boss_putrid_aura", "heroes/bosses/zombie/zombie_boss_putrid_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_boss_putrid_aura_debuff", "heroes/bosses/zombie/zombie_boss_putrid_aura", LUA_MODIFIER_MOTION_NONE)

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
    Isdebuff = function(self) return true end,
}

zombie_boss_putrid_aura = class(ItemBaseClass)
modifier_zombie_boss_putrid_aura = class(zombie_boss_putrid_aura)
modifier_zombie_boss_putrid_aura_debuff = class(ItemBaseClassDebuff)
-------------
function zombie_boss_putrid_aura:GetIntrinsicModifierName()
    return "modifier_zombie_boss_putrid_aura"
end

function modifier_zombie_boss_putrid_aura:GetEffectName()
    return "particles/units/heroes/hero_undying/undying_fg_aura.vpcf"
end

function modifier_zombie_boss_putrid_aura:IsAura()
    return true
end

function modifier_zombie_boss_putrid_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_zombie_boss_putrid_aura:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_zombie_boss_putrid_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_zombie_boss_putrid_aura:GetModifierAura()
    return "modifier_zombie_boss_putrid_aura_debuff"
end

function modifier_zombie_boss_putrid_aura:GetAuraSearchFlags()
    return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_zombie_boss_putrid_aura:GetAuraEntityReject(target)
    return false
end
-------------
function modifier_zombie_boss_putrid_aura_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
end

function modifier_zombie_boss_putrid_aura_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_zombie_boss_putrid_aura_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetSpecialValueFor("damage_amp")
end