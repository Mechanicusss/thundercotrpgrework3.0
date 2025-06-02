LinkLuaModifier("modifier_terrorblade_metamorphosis_unleashed_custom", "heroes/hero_terrorblade/terrorblade_metamorphosis_unleashed_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

terrorblade_metamorphosis_unleashed_custom = class(ItemBaseClass)
modifier_terrorblade_metamorphosis_unleashed_custom = class(terrorblade_metamorphosis_unleashed_custom)
-------------
function terrorblade_metamorphosis_unleashed_custom:GetIntrinsicModifierName()
    return "modifier_terrorblade_metamorphosis_unleashed_custom"
end


function modifier_terrorblade_metamorphosis_unleashed_custom:DeclareFunctions()
    local funcs = {
        --MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE
    }
    return funcs
end

function modifier_terrorblade_metamorphosis_unleashed_custom:GetModifierProcAttack_BonusDamage_Pure(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        local ability = self:GetAbility()

        local damageConversion = ability:GetLevelSpecialValueFor("damage_conversion_pct", (ability:GetLevel() - 1))

        local total = params.damage * (damageConversion / 100)
        
        return total
    end
end

function modifier_terrorblade_metamorphosis_unleashed_custom:OnCreated()
    self.parent = self:GetParent()
end

--[[
function modifier_terrorblade_metamorphosis_unleashed_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() or not caster:HasModifier("modifier_terrorblade_metamorphosis") then
        return
    end

    local ability = self:GetAbility()
    local damageConversion = ability:GetLevelSpecialValueFor("damage_conversion_pct", (ability:GetLevel() - 1))

    ApplyDamage({
        victim = victim, 
        attacker = caster, 
        damage = event.damage * (damageConversion / 100), 
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
    })
end
--]]

function modifier_terrorblade_metamorphosis_unleashed_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/econ/items/terrorblade/terrorblade_back_ti8/terrorblade_sunder_ti8_dark_dust.vpcf"
    local sound_cast = "Hero_Terrorblade.Sunder.Target"

    -- Get Data
    local forward = (target:GetOrigin()-self.parent:GetOrigin()):Normalized()

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
    ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
    ParticleManager:SetParticleControlForward( effect_cast, 0, forward )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    --EmitSoundOn( sound_cast, target )
end