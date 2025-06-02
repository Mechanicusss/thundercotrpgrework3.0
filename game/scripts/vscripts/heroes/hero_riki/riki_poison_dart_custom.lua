LinkLuaModifier("modifier_riki_poison_dart_custom_debuff", "heroes/hero_riki/riki_poison_dart_custom.lua", LUA_MODIFIER_MOTION_NONE)

local BaseClass = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

local BaseClassDebuff = {
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
}

riki_poison_dart_custom = class(BaseClass)
modifier_riki_poison_dart_custom_debuff = class(BaseClassDebuff)
-------------------------------
function riki_poison_dart_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    local info = {
        Target = enemy,
        Source = self.parent,
        Ability = self:GetAbility(),    
        
        EffectName = self.projectile_name,
        iMoveSpeed = self.projectile_speed,
        bDodgeable = true,                           -- Optional
        -- bIsAttack = true,                                -- Optional
    }

    local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
        radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_CLOSEST, false)

    for _,enemy in ipairs(enemies) do
        if not enemy:IsAlive() then break end 

        
        ProjectileManager:CreateTrackingProjectile(info)
    end
end
-------------------------------
function modifier_riki_poison_dart_custom:DeclareFunctions()
    return {
        
    }
end
---------------------------------
function modifier_riki_poison_dart_custom_debuff:GetEffectName()
    return "particles/items2_fx/sange_maim.vpcf"
end

function modifier_riki_poison_dart_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_riki_poison_dart_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_riki_poison_dart_custom_debuff:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_reduction")
end