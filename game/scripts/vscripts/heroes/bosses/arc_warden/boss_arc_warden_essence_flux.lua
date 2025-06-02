LinkLuaModifier("modifier_boss_arc_warden_essence_flux", "heroes/bosses/arc_warden/boss_arc_warden_essence_flux", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_arc_warden_essence_flux_aura", "heroes/bosses/arc_warden/boss_arc_warden_essence_flux", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_arc_warden_essence_flux_debuff", "heroes/bosses/arc_warden/boss_arc_warden_essence_flux", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

boss_arc_warden_essence_flux = class(ItemBaseClass)
modifier_boss_arc_warden_essence_flux = class(boss_arc_warden_essence_flux)
modifier_boss_arc_warden_essence_flux_aura = class(ItemBaseClassAura)
modifier_boss_arc_warden_essence_flux_debuff = class(ItemBaseClassAura)
-------------
function boss_arc_warden_essence_flux:GetIntrinsicModifierName()
    return "modifier_boss_arc_warden_essence_flux"
end

function boss_arc_warden_essence_flux:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
-------------
function modifier_boss_arc_warden_essence_flux:IsAura()
    return true
end
  
function modifier_boss_arc_warden_essence_flux:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_boss_arc_warden_essence_flux:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_arc_warden_essence_flux:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_boss_arc_warden_essence_flux:GetModifierAura()
    return "modifier_boss_arc_warden_essence_flux_aura"
end

function modifier_boss_arc_warden_essence_flux:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_boss_arc_warden_essence_flux:GetAuraEntityReject()
    return false
end
----------------------
function modifier_boss_arc_warden_essence_flux_aura:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(1.0)
end

function modifier_boss_arc_warden_essence_flux_aura:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("ally_radius")

    local allies = FindUnitsInRadius(
        parent:GetTeam(),
        parent:GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_CLOSEST,
        false
    )

    local numberOfAllies = #allies - 1 -- Not including ourselves

    if numberOfAllies < 1 then
        parent:AddNewModifier(self:GetCaster(), ability, "modifier_boss_arc_warden_essence_flux_debuff", {})
    else
        parent:RemoveModifierByName("modifier_boss_arc_warden_essence_flux_debuff")
    end
end
----------------
function modifier_boss_arc_warden_essence_flux_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE 
    }
end

function modifier_boss_arc_warden_essence_flux_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_boss_arc_warden_essence_flux_debuff:OnCreated()
    if not IsServer() then return end 

    EmitSoundOn("Hero_ArcWarden.Flux.Cast", self:GetParent())
    EmitSoundOn("Hero_ArcWarden.Flux.Target", self:GetParent())

    self:StartIntervalThink(0.1)
end

function modifier_boss_arc_warden_essence_flux_debuff:OnDestroy()
    if not IsServer() then return end 

    StopSoundOn("Hero_ArcWarden.Flux.Target", self:GetParent())
end

function modifier_boss_arc_warden_essence_flux_debuff:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsRealHero() then return end 
    
    local ability = self:GetAbility()
    local damage = ability:GetSpecialValueFor("max_hp_damage_pct")

    if not parent:HasModifier("modifier_boss_arc_warden_essence_flux_aura") then self:Destroy() return end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = parent,
        damage = parent:GetMaxHealth() * (damage/100) * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
        ability = ability
    })
end

function modifier_boss_arc_warden_essence_flux_debuff:GetEffectName()
    return "particles/units/heroes/hero_arc_warden/arc_warden_flux_tempest_tgt.vpcf"
end