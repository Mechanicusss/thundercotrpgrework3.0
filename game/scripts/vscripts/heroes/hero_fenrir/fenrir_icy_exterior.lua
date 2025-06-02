LinkLuaModifier("modifier_fenrir_icy_exterior", "heroes/hero_fenrir/fenrir_icy_exterior", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

fenrir_icy_exterior = class(ItemBaseClass)
modifier_fenrir_icy_exterior = class(fenrir_icy_exterior)
-------------
function fenrir_icy_exterior:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target == nil then return end

    if target:HasModifier("modifier_fenrir_icy_exterior") then
        target:RemoveModifierByName("modifier_fenrir_icy_exterior")
    end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_fenrir_icy_exterior", {
        duration = duration
    })

    EmitSoundOn("hero_Crystal.frostbite", target)
end
------------
function modifier_fenrir_icy_exterior:DeclareFunctions()
    return {
         MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
         MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
         MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_fenrir_icy_exterior:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    local stacks = ability:GetSpecialValueFor("max_stacks")

    self.explosionRadius = ability:GetSpecialValueFor("icicle_explosion_radius")
    self.icicleDamage = ability:GetSpecialValueFor("icicle_max_hp_damage")

    self.block = parent:GetMaxHealth() * (ability:GetSpecialValueFor("block_hp_pct")/100)

    self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_shard_frostbite.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.particle,
        0,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    self:SetStackCount(stacks)
end

function modifier_fenrir_icy_exterior:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.particle ~= nil then
        ParticleManager:DestroyParticle(self.particle, true)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end

function modifier_fenrir_icy_exterior:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_fenrir_icy_exterior:GetModifierMagical_ConstantBlock()
    if self:GetStackCount() > 1 then
        self:DecrementStackCount()
    else
        self:Destroy()
    end

    return self.block * self:GetStackCount()
end

function modifier_fenrir_icy_exterior:GetModifierPhysical_ConstantBlock()
    if self:GetStackCount() > 1 then
        self:DecrementStackCount()
    else
        self:Destroy()
    end

    return self.block * self:GetStackCount()
end

function modifier_fenrir_icy_exterior:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local attacker = event.attacker
    local victim = event.target

    if parent ~= victim then return end
    if event.target == event.attacker then return end
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
    if not caster:HasModifier("modifier_item_aghanims_shard") then return end

    local damage = parent:GetMaxHealth() * (self.icicleDamage/100)
    local point = attacker:GetAbsOrigin()

    self:PlayEffects(point, attacker)

    local enemies = FindUnitsInRadius(
        parent:GetTeamNumber(),   -- int, your team number
        point,  -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self.explosionRadius,  -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    -- damage units
    for _,enemy in pairs(enemies) do
        ApplyDamage({
            attacker = caster,
            victim = enemy,
            damage = damage,
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = ability
        })

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage, nil)
    end
end

function modifier_fenrir_icy_exterior:PlayEffects(point, unit)
    -- Play particles
    local particle_cast = "particles/units/heroes/hero_crystalmaiden_persona/cm_persona_freezing_field_explosion.vpcf"

    -- Create particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, point )

    -- Play sound
    local sound_cast = "hero_Crystal.freezingField.explosion"
    EmitSoundOnLocationWithCaster( point, sound_cast, unit )
end