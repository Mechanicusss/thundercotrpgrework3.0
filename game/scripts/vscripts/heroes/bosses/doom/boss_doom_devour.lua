LinkLuaModifier("modifier_boss_doom_devour", "heroes/bosses/doom/boss_doom_devour", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_doom_devour_buff", "heroes/bosses/doom/boss_doom_devour", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return true end,
}

boss_doom_devour = class(ItemBaseClass)
modifier_boss_doom_devour = class(boss_doom_devour)
modifier_boss_doom_devour_buff = class(ItemBaseClassBuff)
-------------
function boss_doom_devour:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    local target = self:GetCursorTarget()

    self.vfx = ParticleManager:CreateParticle("particles/econ/items/doom/doom_ti8_immortal_arms/doom_ti8_immortal_devour.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl( self.vfx, 0, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 1, target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 4, target:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex(self.vfx)

    if caster:GetLevel() > target:GetLevel() then
        target:Kill(self, caster)
    end

    EmitSoundOn("Hero_DoomBringer.DevourCast", target)

    if not target:IsAlive() then
        caster:AddNewModifier(target, self, "modifier_boss_doom_devour_buff", { duration = self:GetSpecialValueFor("duration") })
    end
end
------------
function modifier_boss_doom_devour_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE 
    }
end

function modifier_boss_doom_devour_buff:GetModifierPreAttack_BonusDamage()
    return self:GetCaster():GetMaxHealth() * (self:GetAbility():GetSpecialValueFor("hp_to_dmg_pct")/100)
end