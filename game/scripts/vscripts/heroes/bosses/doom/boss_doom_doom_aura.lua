LinkLuaModifier("modifier_boss_doom_doom_aura", "heroes/bosses/doom/boss_doom_doom_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_doom_doom_aura_debuff", "heroes/bosses/doom/boss_doom_doom_aura", LUA_MODIFIER_MOTION_NONE)

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

boss_doom_doom_aura = class(ItemBaseClass)
modifier_boss_doom_doom_aura = class(boss_doom_doom_aura)
modifier_boss_doom_doom_aura_debuff = class(ItemBaseClassDebuff)
-------------
function boss_doom_doom_aura:GetIntrinsicModifierName()
    return "modifier_boss_doom_doom_aura"
end
-------------
function modifier_boss_doom_doom_aura:DeclareFunctions()
    return {
        MODFIIER_EVENT_ON_DEATH
    }
end

function modifier_boss_doom_doom_aura:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    StopSoundOn("Hero_DoomBringer.Doom", parent)

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end
end

function modifier_boss_doom_doom_aura:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl( self.vfx, 0, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 3, parent:GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 4, parent:GetAbsOrigin() )

    EmitSoundOn("Hero_DoomBringer.Doom", parent)
end

function modifier_boss_doom_doom_aura:IsAura()
    return true
end
  
function modifier_boss_doom_doom_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_boss_doom_doom_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_doom_doom_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_boss_doom_doom_aura:GetModifierAura()
    return "modifier_boss_doom_doom_aura_debuff"
end

function modifier_boss_doom_doom_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_boss_doom_doom_aura:GetAuraEntityReject(target)
    return false
end
---------------
function modifier_boss_doom_doom_aura_debuff:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, true)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_boss_doom_doom_aura_debuff:OnCreated(params)
    if not IsServer() then return end

    local caster = self:GetCaster()

    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 4, self:GetParent():GetAbsOrigin() )

    EmitSoundOn("Hero_DoomBringer.Doom.Creep", self:GetParent())

    self:StartIntervalThink(1)
end

function modifier_boss_doom_doom_aura_debuff:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    ApplyDamage({
        victim = parent, 
        attacker = caster, 
        damage = ability:GetSpecialValueFor("damage"), 
        damage_type = ability:GetAbilityDamageType(),
        ability = ability
    })

    EmitSoundOn("n_black_dragon.Fireball.Target", parent)
end

function modifier_boss_doom_doom_aura_debuff:CheckState()
    return {
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_MUTED] = true,
        [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    }
end