obsidian_arcane_orb_custom = class({})
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_obsidian_arcane_orb_custom", "heroes/hero_obsidian/obsidian_arcane_orb_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_obsidian_arcane_orb_custom_stack", "heroes/hero_obsidian/obsidian_arcane_orb_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_obsidian_essence_flux", "heroes/hero_obsidian/obsidian_essence_flux", LUA_MODIFIER_MOTION_NONE)

require("heroes/hero_obsidian/obsidian_essence_flux")
--------------------------------------------------------------------------------
-- Passive Modifier
function obsidian_arcane_orb_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Ability Start
function obsidian_arcane_orb_custom:OnSpellStart()
end

function obsidian_arcane_orb_custom:GetManaCost(level)
    return self:GetCaster():GetMana() * (self:GetSpecialValueFor("mana_cost_pct")/100)
end

--------------------------------------------------------------------------------
-- Orb Effects
function obsidian_arcane_orb_custom:GetProjectileName()
    return "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_arcane_orb.vpcf"
end

function obsidian_arcane_orb_custom:OnOrbFire( params )
    -- play effects
    local sound_cast = "Hero_ObsidianDestroyer.ArcaneOrb"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

function obsidian_arcane_orb_custom:OnOrbImpact( params )
    local caster = self:GetCaster()

    -- get data
    local duration = self:GetSpecialValueFor( "int_steal_duration" )
    --local steal = caster:GetBaseIntellect() * (self:GetSpecialValueFor( "int_steal" )/100)
    local steal = caster:GetMana() * (self:GetSpecialValueFor("mana_cost_pct")/100) * (self:GetSpecialValueFor( "int_steal" )/100)
    local attack_to_magic = self:GetSpecialValueFor( "attack_to_magic" )
    local radius = self:GetSpecialValueFor( "radius" )

    -- precache damage
    local damage = caster:GetMana() * (attack_to_magic/100)
    local damageTable = {
        -- victim = target,
        attacker = caster,
        damage = damage,
        damage_type = self:GetAbilityDamageType(),
        ability = self, --Optional.
    }
    -- ApplyDamage(damageTable)

    -- find enemies
    local enemies = FindUnitsInRadius(
        caster:GetTeamNumber(), -- int, your team number
        params.target:GetOrigin(),  -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        radius, -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        0,  -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    for _,enemy in pairs(enemies) do
        -- damage
        damageTable.victim = enemy
        ApplyDamage( damageTable )

        -- overhead event
        SendOverheadEventMessage(
            nil,
            OVERHEAD_ALERT_BONUS_SPELL_DAMAGE,
            enemy,
            damageTable.damage,
            nil
        )
    end

    --[[
    -- add debuff
    params.target:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_obsidian_arcane_orb_custom", -- modifier name
        {
            duration = duration,
            steal = steal,
        } -- kv
    )
    --]]

    -- add buff
    caster:AddNewModifier(
        caster, -- player source
        self, -- ability source
        "modifier_obsidian_arcane_orb_custom", -- modifier name
        {
            duration = duration,
            steal = steal,
        } -- kv
    )

    -- play effects
    local sound_cast = "Hero_ObsidianDestroyer.ArcaneOrb.Impact"
    EmitSoundOn( sound_cast, params.target )
end

modifier_obsidian_arcane_orb_custom_stack = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_obsidian_arcane_orb_custom_stack:IsHidden()
    return true
end

function modifier_obsidian_arcane_orb_custom_stack:IsPurgable()
    return false
end

function modifier_obsidian_arcane_orb_custom_stack:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE 
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_obsidian_arcane_orb_custom_stack:OnCreated( kv )
    if not IsServer() then return end
    self.stack = kv.stack
end

function modifier_obsidian_arcane_orb_custom_stack:OnRemoved()
end

function modifier_obsidian_arcane_orb_custom_stack:OnDestroy()
    if not IsServer() then return end

    if not self.modifier or self.modifier == nil or self.modifier:IsNull() then return end

    if self.modifier then
        self.modifier:RemoveStack( self.stack )
    end
end

modifier_obsidian_arcane_orb_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_obsidian_arcane_orb_custom:IsHidden()
    return false
end

function modifier_obsidian_arcane_orb_custom:IsDebuff()
    return self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
end

function modifier_obsidian_arcane_orb_custom:IsStunDebuff()
    return false
end

function modifier_obsidian_arcane_orb_custom:IsPurgable()
    return false
end

function modifier_obsidian_arcane_orb_custom:RemoveOnDeath()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_obsidian_arcane_orb_custom:OnCreated( kv )
    -- reduce intel if debuff, add if buff
    self.debuff = self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber()
    self.mult = 1
    if self.debuff then
        self.mult = -1
    end

    if not IsServer() then return end

    self:AddStack( kv.steal, kv.duration )
end

function modifier_obsidian_arcane_orb_custom:OnRefresh( kv )
    if not IsServer() then return end

    self:AddStack( kv.steal, kv.duration )
end

function modifier_obsidian_arcane_orb_custom:OnRemoved()
end

function modifier_obsidian_arcane_orb_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_obsidian_arcane_orb_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    }

    return funcs
end

function modifier_obsidian_arcane_orb_custom:GetModifierBonusStats_Intellect()
    return self.mult * self:GetStackCount()
end

--------------------------------------------------------------------------------
-- Helper
function modifier_obsidian_arcane_orb_custom:AddStack( value, duration )
    -- set stack
    self:SetStackCount( self:GetStackCount() + value )

    -- add stack modifier
    local modifier = self:GetParent():AddNewModifier(
        self:GetCaster(), -- player source
        self:GetAbility(), -- ability source
        "modifier_obsidian_arcane_orb_custom_stack", -- modifier name
        {
            duration = duration,
            stack = value,
        } -- kv
    )

    -- set stack parent modifier as this
    modifier.modifier = self

    -- reduce some mana because of stat loss
    if self.debuff then
        self:GetParent():Script_ReduceMana( value * 12, nil )
    end
end

function modifier_obsidian_arcane_orb_custom:RemoveStack( value )
    -- set stack
    self:SetStackCount( self:GetStackCount() - value )

    -- restore some mana because of stat gain
    if self.debuff then
        self:GetParent():GiveMana( value * 12 )
    end

    -- if reach zero, destroy
    if self:GetStackCount()<=0 then
        self:Destroy()
    end
end