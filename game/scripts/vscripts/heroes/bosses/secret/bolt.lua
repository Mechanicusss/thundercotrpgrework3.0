LinkLuaModifier("modifier_secret_zeus_lightning_bolt", "heroes/bosses/secret/bolt", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_secret_zeus_lightning_bolt_stun", "heroes/bosses/secret/bolt", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

secret_zeus_lightning_bolt = class(ItemBaseClass)
modifier_secret_zeus_lightning_bolt = class(secret_zeus_lightning_bolt)
modifier_secret_zeus_lightning_bolt_stun = class(ItemBaseClassDebuff)
-------------
function modifier_secret_zeus_lightning_bolt_stun:CheckState()
    local state = {
        [MODIFIER_STATE_STUNNED] = true
    }
    return state
end
-------------
function secret_zeus_lightning_bolt:GetIntrinsicModifierName()
    return "modifier_secret_zeus_lightning_bolt"
end

function modifier_secret_zeus_lightning_bolt:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_secret_zeus_lightning_bolt:OnCreated()
    self.parent = self:GetParent()
end

function modifier_secret_zeus_lightning_bolt:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    if not ability:IsCooldownReady() then return end
    if victim:IsMagicImmune() then return end

    ApplyDamage({
        victim = victim, 
        attacker = caster, 
        damage = ability:GetSpecialValueFor("damage"), 
        damage_type = DAMAGE_TYPE_MAGICAL
    })

    victim:AddNewModifier(caster, ability, "modifier_secret_zeus_lightning_bolt_stun", { duration = ability:GetSpecialValueFor("stun") })
    
    self:PlayEffects(victim)
    self:PlayEffects2(victim)
    self:PlayEffects3(victim)

    ability:UseResources(false, false, false, true)
end

function modifier_secret_zeus_lightning_bolt:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/zeus/lightning_weapon_fx/zuus_lightning_bolt_immortal_lightning.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetAbsOrigin()+Vector(0,0,2000))
    ParticleManager:SetParticleControl( effect_cast, 3, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
    EmitSoundOn(sound_cast, target)
end

function modifier_secret_zeus_lightning_bolt:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/zeus/lightning_weapon_fx/zuus_lightning_bolt_bodyarc_immortal_lightningyzuus_lightning_bolt_bodyarc_immortal_lightning.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt.Righteous"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl( effect_cast, 2, target:GetAbsOrigin())
    ParticleManager:SetParticleControl( effect_cast, 3, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
end

function modifier_secret_zeus_lightning_bolt:PlayEffects3(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/arc_warden/arc_warden_ti9_immortal/arc_warden_ti9_wraith_cast_lightning.vpcf"
    local sound_cast = "Hero_Zuus.LightningBolt.Righteous"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
end