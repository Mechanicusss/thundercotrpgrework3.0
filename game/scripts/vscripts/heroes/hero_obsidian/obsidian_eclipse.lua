LinkLuaModifier("modifier_obsidian_eclipse_buff", "heroes/hero_obsidian/obsidian_eclipse", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClassBuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_obsidian_eclipse_buff = class(ItemBaseClassBuff)
obsidian_eclipse = class({})
--------------------------------------------------------------------------------
-- Custom KV
-- AOE Radius
function obsidian_eclipse:GetAOERadius()
    return self:GetSpecialValueFor( "radius" )
end

function obsidian_eclipse:GetManaCost()
    return self:GetCaster():GetMana() * (self:GetSpecialValueFor( "mana_drain" )/100)
end
--------------------------------------------------------------------------------
-- Ability Start
function obsidian_eclipse:OnSpellStart()
    -- unit identifier
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    -- load data
    local radius = self:GetSpecialValueFor( "radius" )
    local mana_loss = self:GetSpecialValueFor( "mana_drain" )
    local mana = caster:GetMana() * (mana_loss/100)
    
    caster:Script_ReduceMana(mana, nil)

    -- precache int and damage
    local damageTable = {
        -- victim = target,
        attacker = caster,
        damage = mana,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }

    -- find enemies
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        point,  -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC),  -- int, type filter
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD,    -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        damageTable.victim = enemy
        ApplyDamage(damageTable)
    end

    -- play effects
    self:PlayEffects( point, radius )

    caster:AddNewModifier(caster, self, "modifier_obsidian_eclipse_buff", {
        duration = self:GetSpecialValueFor("duration"),
        damage = mana
    })
end

--------------------------------------------------------------------------------
function obsidian_eclipse:PlayEffects( point, radius )
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf"
    local sound_cast1 = "Hero_ObsidianDestroyer.Sanityeclipse.Cast"
    local sound_cast2 = "Hero_ObsidianDestroyer.Sanityeclipse"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( effect_cast, 0, point )
    ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, 0 ) )
    ParticleManager:SetParticleControl( effect_cast, 2, Vector( radius, radius, radius ) )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast1, self:GetCaster() )
    EmitSoundOnLocationWithCaster( point, sound_cast2, self:GetCaster() )
end

function modifier_obsidian_eclipse_buff:OnCreated(params)
    self:SetHasCustomTransmitterData(true)

    self.damage = params.damage

    self:InvokeBonusDamage()
end

function modifier_obsidian_eclipse_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
    return funcs
end

function modifier_obsidian_eclipse_buff:GetModifierBonusStats_Intellect()
    return self.fDamage
end

function modifier_obsidian_eclipse_buff:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_obsidian_eclipse_buff:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_obsidian_eclipse_buff:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end