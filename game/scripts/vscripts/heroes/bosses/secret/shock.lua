LinkLuaModifier("modifier_secret_zeus_static_field", "heroes/bosses/secret/shock", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_secret_zeus_static_field_slow", "heroes/bosses/secret/shock", LUA_MODIFIER_MOTION_NONE)

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

secret_zeus_static_field = class(ItemBaseClass)
modifier_secret_zeus_static_field = class(secret_zeus_static_field)
modifier_secret_zeus_static_field_slow = class(ItemBaseClassDebuff)
-------------
function modifier_secret_zeus_static_field_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,--GetModifierMoveSpeedBonus_Percentage
    }
    return funcs
end

function modifier_secret_zeus_static_field_slow:GetModifierMoveSpeedBonus_Percentage()
    return (-100)
end
-------------
function secret_zeus_static_field:GetIntrinsicModifierName()
    return "modifier_secret_zeus_static_field"
end

function modifier_secret_zeus_static_field:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_secret_zeus_static_field:OnCreated()
    self.parent = self:GetParent()
end

function modifier_secret_zeus_static_field:OnTakeDamage(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.unit

    if victim ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()

    if unit:IsMagicImmune() or not ability:IsCooldownReady() then return end

    ApplyDamage({
        victim = unit, 
        attacker = caster, 
        damage = unit:GetMaxHealthTCOTRPG() * (ability:GetSpecialValueFor("damage_hp_pct")/100), 
        damage_type = DAMAGE_TYPE_MAGICAL
    })

    self:PlayEffects(unit)

    unit:AddNewModifier(caster, ability, "modifier_secret_zeus_static_field_slow", { duration = 1.0 })
    ability:UseResources(false, false, false, true)
end

function modifier_secret_zeus_static_field:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/zeus/arcana_chariot/zeus_arcana_static_field.vpcf"
    local sound_cast = "Hero_Zuus.StaticField"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControl( effect_cast, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl( effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex( effect_cast )
    -- Create Sound
    EmitSoundOn(sound_cast, target)
end