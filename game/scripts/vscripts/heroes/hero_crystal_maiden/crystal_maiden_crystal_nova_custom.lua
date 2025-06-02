LinkLuaModifier("modifier_crystal_maiden_crystal_nova_custom", "heroes/hero_crystal_maiden/crystal_maiden_crystal_nova_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_crystal_nova_custom_debuff", "heroes/hero_crystal_maiden/crystal_maiden_crystal_nova_custom", LUA_MODIFIER_MOTION_NONE)

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
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

crystal_maiden_crystal_nova_custom = class(ItemBaseClass)
creep_ancient_apparition_crystal_nova_custom = crystal_maiden_crystal_nova_custom
modifier_crystal_maiden_crystal_nova_custom = class(crystal_maiden_crystal_nova_custom)
modifier_crystal_maiden_crystal_nova_custom_debuff = class(ItemBaseClassDebuff)
-------------
function crystal_maiden_crystal_nova_custom:GetIntrinsicModifierName()
    return "modifier_crystal_maiden_crystal_nova_custom"
end

function crystal_maiden_crystal_nova_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    modifier_crystal_maiden_crystal_nova_custom:FireCrystalNova(self, caster, point)
end

function crystal_maiden_crystal_nova_custom:GetCastRange()
    return self:GetCaster():Script_GetAttackRange()
end

function crystal_maiden_crystal_nova_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function crystal_maiden_crystal_nova_custom:GetCooldown(level)
    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        return 0
    else
        return self.BaseClass.GetCooldown(self, level)
    end
end
---------
function modifier_crystal_maiden_crystal_nova_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_crystal_maiden_crystal_nova_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent:IsIllusion() or parent:IsMuted() then return end

    local victim = event.target

    if not victim:IsBaseNPC() then return end

    local ability = self:GetAbility()

    if not ability:IsFullyCastable() or not ability:GetAutoCastState() then return end

    --self:FireCrystalNova(ability, parent, victim:GetOrigin())
    SpellCaster:Cast(ability, victim:GetAbsOrigin(), true)

    ability:UseResources(true, false, false, true)
end


function modifier_crystal_maiden_crystal_nova_custom:FireCrystalNova(ability, caster, pos)
    local radius = ability:GetSpecialValueFor("radius")

    EmitSoundOn("hero_Crystal.CrystalNovaCast", caster)

    self:PlayEffects(pos, radius)

    EmitSoundOn("Hero_Crystal.CrystalNova.Yulsaria", caster)

    local intellectDamage = 0
    if caster:IsRealHero() then
        intellectDamage = caster:GetBaseIntellect()
    end

    local damage = ability:GetSpecialValueFor("damage") + (intellectDamage * (ability:GetSpecialValueFor("int_to_damage")/100))

    local victims = FindUnitsInRadius(caster:GetTeam(), pos, nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if victim:IsMagicImmune() or victim:IsInvulnerable() then break end

        if caster:HasModifier("modifier_item_aghanims_shard") and victim:HasModifier("modifier_crystal_maiden_frostbite_custom_debuff_frozen") then
            damage = damage * 2
        end

        ApplyDamage({
            victim = victim,
            attacker = caster,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })

        victim:AddNewModifier(caster, ability, "modifier_crystal_maiden_crystal_nova_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    AddFOWViewer(
        caster:GetTeamNumber(),
        pos,
        radius,
        ability:GetSpecialValueFor("vision_duration"),
        true
    )
end

function modifier_crystal_maiden_crystal_nova_custom:PlayEffects(pos, radius)
    -- Get Resources
    local particle_cast = "particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )

    ParticleManager:SetParticleControl( effect_cast, 0, pos )
    --ParticleManager:SetParticleControl( effect_cast, 1, pos )
    ParticleManager:SetParticleControl( effect_cast, 2, pos )

    ParticleManager:ReleaseParticleIndex( effect_cast )
end
---------------
function modifier_crystal_maiden_crystal_nova_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }

    return funcs
end

function modifier_crystal_maiden_crystal_nova_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movespeed_slow")
end

function modifier_crystal_maiden_crystal_nova_custom_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attackspeed_slow")
end