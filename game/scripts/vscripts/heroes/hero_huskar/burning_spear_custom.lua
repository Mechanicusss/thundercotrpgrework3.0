huskar_burning_spear_custom = class({})
LinkLuaModifier( "modifier_huskar_burning_spear_custom", "heroes/hero_huskar/burning_spear_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_huskar_burning_spear_custom_stack", "heroes/hero_huskar/burning_spear_custom.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function huskar_burning_spear_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Orb Effects
function huskar_burning_spear_custom:GetProjectileName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear.vpcf"
end

function huskar_burning_spear_custom:OnOrbFire( params )
    -- health cost
    local damageType = self:GetAbilityDamageType()
    --[[
    local hasTalent = self:GetCaster():HasTalent("special_bonus_unique_huskar_5")
    if hasTalent then
        damageType = DAMAGE_TYPE_PURE
    end
    --]]

    local selfDamage = self:GetCaster():GetMaxHealth() * (self:GetSpecialValueFor("health_cost")/100)

    local mayhem = self:GetCaster():FindAbilityByName("huskar_mayhem_custom")
    if mayhem and mayhem:GetLevel() > 0 then
        selfDamage = (self:GetCaster():GetMaxHealth() * (mayhem:GetSpecialValueFor("max_hp_threshold") / 100)) * (self:GetSpecialValueFor("health_cost")/100)
    end

    local damageTable = {
        victim = self:GetCaster(),
        attacker = self:GetCaster(),
        damage = selfDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        --ability = self, --Optional.
        damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, --Optional.
    }
    ApplyDamage(damageTable)
end

function huskar_burning_spear_custom:OnOrbImpact( params )
    local duration = self:GetDuration()

    params.target:AddNewModifier(
        self:GetCaster(), -- player source
        self, -- ability source
        "modifier_huskar_burning_spear_custom", -- modifier name
        { duration = duration } -- kv
    )

    -- play effects
    local sound_cast = "Hero_Huskar.Burning_Spear.Cast"
    EmitSoundOn( sound_cast, self:GetCaster() )
end

--------------------------------------------------------------------------------
-- Ability Start
function huskar_burning_spear_custom:OnSpellStart()
end

modifier_huskar_burning_spear_custom = class({})
local tempTable = require("libraries/tempTable")

--------------------------------------------------------------------------------
-- Classifications
function modifier_huskar_burning_spear_custom:IsHidden()
    return false
end

function modifier_huskar_burning_spear_custom:IsDebuff()
    return true
end

function modifier_huskar_burning_spear_custom:IsStunDebuff()
    return false
end

function modifier_huskar_burning_spear_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_huskar_burning_spear_custom:OnCreated( kv )
    -- reference
    if IsServer() then
        local hasTalent = self:GetCaster():HasTalent("special_bonus_unique_huskar_2")
        local healthCost = self:GetAbility():GetSpecialValueFor( "health_cost" )
        --[[if hasTalent then
            healthCost = healthCost + 4
        end--]]

        self.dps = self:GetCaster():GetMaxHealth() * (healthCost/100)

        local mayhem = self:GetCaster():FindAbilityByName("huskar_mayhem_custom")
        if mayhem and mayhem:GetLevel() > 0 then
            self.dps = (self:GetCaster():GetMaxHealth() * (mayhem:GetSpecialValueFor("max_hp_threshold") / 100)) * (healthCost/100)
        end

        self.dps = self.dps + (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster()) * (self:GetAbility():GetSpecialValueFor( "damage_from_attack" )/100))

        local duration = self:GetAbility():GetDuration()
        
        -- add stack modifier
        local this = tempTable:AddATValue( self )
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_huskar_burning_spear_custom_stack", -- modifier name
            {
                duration = duration,
                modifier = this,
            } -- kv
        )

        -- increment stack
        self:IncrementStackCount()

        -- precache damage
        local damageType = self:GetAbility():GetAbilityDamageType()
        --[[
        local hasTalent = self:GetCaster():HasTalent("special_bonus_unique_huskar_5")
        if hasTalent then
            damageType = DAMAGE_TYPE_PURE
        end
        --]]
        local flags = DOTA_DAMAGE_FLAG_NONE

        self.damageTable = {
            victim = self:GetParent(),
            attacker = self:GetCaster(),
            -- damage = 500,
            damage_type = damageType,
            damage_flags = flags,
            ability = self:GetAbility(), --Optional.
        }

        -- start interval
        self:StartIntervalThink( 1 )
    end
end

function modifier_huskar_burning_spear_custom:OnRefresh( kv )
    -- references
    if IsServer() then
        local hasTalent = self:GetCaster():HasTalent("special_bonus_unique_huskar_2")
        local healthCost = self:GetAbility():GetSpecialValueFor( "health_cost" )
        --[[
        if hasTalent then
            healthCost = healthCost + 4
        end--]]
        
        self.dps = self:GetCaster():GetMaxHealth() * (healthCost/100)

        local duration = self:GetAbility():GetDuration()

        -- add stack
        local this = tempTable:AddATValue( self )
        self:GetParent():AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_huskar_burning_spear_custom_stack", -- modifier name
            {
                duration = duration,
                modifier = this,
            } -- kv
        )
        
        -- increment stack
        self:IncrementStackCount()
    end
end

function modifier_huskar_burning_spear_custom:OnRemoved()
    -- stop effects
    local sound_cast = "Hero_Huskar.Burning_Spear"
    StopSoundOn( sound_cast, self:GetParent() )
end

function modifier_huskar_burning_spear_custom:OnDestroy()
end

function modifier_huskar_burning_spear_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
    return funcs
end

function modifier_huskar_burning_spear_custom:GetModifierIncomingDamage_Percentage(event)
    if self:GetCaster() ~= event.attacker then return end
    if self:GetParent() ~= event.target then return end

    if not self:GetCaster():HasScepter() then return end

    local res = self:GetAbility():GetSpecialValueFor("magic_res_reduce") * self:GetStackCount()
    local max = self:GetAbility():GetSpecialValueFor("max_res_scepter")

    if res > max then
        res = max
    end

    return res
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_huskar_burning_spear_custom:OnIntervalThink()
    -- apply dot damage
    self.damageTable.damage = self:GetStackCount() * self.dps
    ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_huskar_burning_spear_custom:GetEffectName()
    return "particles/units/heroes/hero_huskar/huskar_burning_spear_debuff.vpcf"
end

function modifier_huskar_burning_spear_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

modifier_huskar_burning_spear_custom_stack = class({})
local tempTable = require("libraries/tempTable")

--------------------------------------------------------------------------------
-- Classifications
function modifier_huskar_burning_spear_custom_stack:IsHidden()
    return true
end

function modifier_huskar_burning_spear_custom_stack:IsPurgable()
    return false
end

function modifier_huskar_burning_spear_custom_stack:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_huskar_burning_spear_custom_stack:OnCreated( kv )
    if IsServer() then
        -- get references
        self.modifier = tempTable:RetATValue( kv.modifier )
    end

    -- play effects
    local sound_cast = "Hero_Huskar.Burning_Spear"
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_huskar_burning_spear_custom_stack:OnRemoved()
    if IsServer() then
        -- decrement stack
        if not self.modifier:IsNull() then
            self.modifier:DecrementStackCount()
        end
    end
end

function modifier_huskar_burning_spear_custom_stack:OnDestroy()
end