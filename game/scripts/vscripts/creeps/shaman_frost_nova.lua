LinkLuaModifier("modifier_shaman_frost_nova", "creeps/shaman_frost_nova", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shaman_frost_nova_debuff", "creeps/shaman_frost_nova", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return true end,
}

shaman_frost_nova = class(ItemBaseClass)
modifier_shaman_frost_nova = class(shaman_frost_nova)
modifier_shaman_frost_nova_debuff = class(ItemBaseClassDebuff)
-------------
function shaman_frost_nova:GetIntrinsicModifierName()
    return "modifier_shaman_frost_nova"
end

function shaman_frost_nova:OnSpellStart()
    if not IsServer() then return end 

    local ability = self
    local caster = self:GetCaster()
    local pos = self:GetCursorPosition()

    local radius = ability:GetSpecialValueFor("radius")

    EmitSoundOn("hero_Crystal.CrystalNovaCast", caster)

    self:PlayEffects(pos, radius)

    EmitSoundOn("Hero_Crystal.CrystalNova.Yulsaria", caster)


    local damage = ability:GetSpecialValueFor("damage")

    local victims = FindUnitsInRadius(caster:GetTeam(), pos, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })

        victim:AddNewModifier(caster, ability, "modifier_shaman_frost_nova_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end
end

function shaman_frost_nova:PlayEffects(pos, radius)
    -- Get Resources
    local particle_cast = "particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )

    ParticleManager:SetParticleControl( effect_cast, 0, pos )
    --ParticleManager:SetParticleControl( effect_cast, 1, pos )
    ParticleManager:SetParticleControl( effect_cast, 2, pos )

    ParticleManager:ReleaseParticleIndex( effect_cast )
end
-----------------
function modifier_shaman_frost_nova_debuff:OnCreated()
    if not IsServer() then return end 

    local parent = self:GetParent()

    EmitSoundOn("hero_Crystal.frostbite", parent)
end

function modifier_shaman_frost_nova_debuff:GetEffectName()
    return "particles/_2econ/items/crystal_maiden/ti7_immortal_shoulder/cm_ti7_immortal_frostbite.vpcf"
end

function modifier_shaman_frost_nova_debuff:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_shaman_frost_nova_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, --GetModifierHealAmplify_PercentageTarget
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, --GetModifierHPRegenAmplify_Percentage
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierLifestealRegenAmplify_Percentage
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE, --GetModifierSpellLifestealRegenAmplify_Percentage
    }

    return funcs
end


function modifier_shaman_frost_nova_debuff:GetModifierHealAmplify_PercentageTarget()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_shaman_frost_nova_debuff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_shaman_frost_nova_debuff:GetModifierLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end

function modifier_shaman_frost_nova_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self:GetAbility():GetSpecialValueFor("degen")
end
