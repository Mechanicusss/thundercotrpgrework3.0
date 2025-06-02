LinkLuaModifier("modifier_spectre_desolate_custom", "heroes/hero_spectre/spectre_desolate_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_desolate_custom_debuff", "heroes/hero_spectre/spectre_desolate_custom", LUA_MODIFIER_MOTION_NONE)

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

spectre_desolate_custom = class(ItemBaseClass)
modifier_spectre_desolate_custom = class(spectre_desolate_custom)
modifier_spectre_desolate_custom_debuff = class(ItemBaseClassDebuff)
-------------
function spectre_desolate_custom:GetIntrinsicModifierName()
    return "modifier_spectre_desolate_custom"
end

function modifier_spectre_desolate_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED 
    }
    return funcs
end

function modifier_spectre_desolate_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_spectre_desolate_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL or event.inflictor ~= nil or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    if caster:IsIllusion() then
        caster = caster:GetOwner():GetAssignedHero()
    end

    local ability = self:GetAbility()
    local radius = ability:GetLevelSpecialValueFor("radius", (ability:GetLevel() - 1))
    local damage = ability:GetLevelSpecialValueFor("bonus_damage", (ability:GetLevel() - 1))
    local damagePct = ability:GetLevelSpecialValueFor("bonus_damage_pct", (ability:GetLevel() - 1))

    local dDamage = damage + (event.damage * (damagePct / 100))

    if not caster:HasModifier("modifier_item_aghanims_shard") then 
        self:PerformDesolate(victim, dDamage)
        return 
    end

    local victims = FindUnitsInRadius(caster:GetTeam(), victim:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,enemy in ipairs(victims) do
        if not enemy:IsAlive() then break end

        self:PerformDesolate(enemy, dDamage)
    end
end

function modifier_spectre_desolate_custom:PerformDesolate(victim, damage)
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    ApplyDamage({
        victim = victim, 
        attacker = caster, 
        damage = damage, 
        damage_type = DAMAGE_TYPE_PURE
    })

    local debuff = victim:FindModifierByName("modifier_spectre_desolate_custom_debuff")
    if not debuff then
        debuff = victim:AddNewModifier(caster, ability, "modifier_spectre_desolate_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        end

        debuff:ForceRefresh()
    end

    self:PlayEffects(victim)
end

function modifier_spectre_desolate_custom:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_spectre/spectre_desolate.vpcf"
    local sound_cast = "Hero_Spectre.Desolate"

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
    EmitSoundOn( sound_cast, target )
end
--------------
function modifier_spectre_desolate_custom_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_spectre_desolate_custom_debuff:GetModifierTotalDamageOutgoing_Percentage(event)
    local caster = self:GetCaster()

    if event.target ~= caster then return end

    return self:GetAbility():GetSpecialValueFor("damage_penalty") * self:GetStackCount()
end

function modifier_spectre_desolate_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_spectre/spectre_desolate_debuff.vpcf"
end