doom_infernal_blade_custom = class({})
LinkLuaModifier( "modifier_generic_orb_effect_lua", "modifiers/modifier_generic_orb_effect_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_stunned_lua", "modifiers/modifier_generic_stunned_lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_doom_infernal_blade_custom", "heroes/hero_doom/doom_infernal_blade_custom", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function doom_infernal_blade_custom:GetIntrinsicModifierName()
    return "modifier_generic_orb_effect_lua"
end

--------------------------------------------------------------------------------
-- Ability Start
function doom_infernal_blade_custom:OnSpellStart()
end

--------------------------------------------------------------------------------
-- Orb Effects
function doom_infernal_blade_custom:OnOrbImpact( params )
    -- get reference
    local duration = self:GetSpecialValueFor( "burn_duration" )
    local bash = self:GetSpecialValueFor( "ministun_duration" )

    if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        -- add debuff
        params.target:AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_doom_infernal_blade_custom", -- modifier name
            { duration = duration, targets = 1 } -- kv
        )

        -- add ministun
        params.target:AddNewModifier(
            self:GetCaster(), -- player source
            self, -- ability source
            "modifier_generic_stunned_lua", -- modifier name
            { duration = bash } -- kv
        )
    else
        local units = FindUnitsInRadius(self:GetCaster():GetTeam(), self:GetCaster():GetAbsOrigin(), nil,
            self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

        for _,unit in ipairs(units) do
            unit:AddNewModifier(
                self:GetCaster(), -- player source
                self, -- ability source
                "modifier_doom_infernal_blade_custom", -- modifier name
                { duration = duration, targets = #units } -- kv
            )

            -- add ministun
            unit:AddNewModifier(
                self:GetCaster(), -- player source
                self, -- ability source
                "modifier_generic_stunned_lua", -- modifier name
                { duration = bash } -- kv
            )
        end
    end
end


modifier_doom_infernal_blade_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_doom_infernal_blade_custom:IsHidden()
    return false
end

function modifier_doom_infernal_blade_custom:IsDebuff()
    return true
end

function modifier_doom_infernal_blade_custom:IsStunDebuff()
    return false
end

function modifier_doom_infernal_blade_custom:IsPurgable()
    return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_doom_infernal_blade_custom:OnCreated( kv )
    if not IsServer() then return end

    -- references
    self.damage = self:GetAbility():GetSpecialValueFor( "burn_damage" ) 
    
    local interval = 1

    -- calculate burn damage
    local selfDamage = (self:GetCaster():GetHealth() * (self.damage/100)) / kv.targets
    self.burnDamage = selfDamage/self:GetAbility():GetSpecialValueFor("burn_duration")

    -- precache damage
    self.damageTable = {
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = self.burnDamage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self, --Optional.
    }

    -- Start interval
    self:StartIntervalThink( interval )

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        self:PlayEffects2()
    end

    -- Play effects
    self:PlayEffects()

    -- Hurt doom
    ApplyDamage({
        victim = self:GetCaster(),
        attacker = self:GetCaster(),
        damage = selfDamage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    })

    -- Hurt the victim
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = selfDamage,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self
    })
end

function modifier_doom_infernal_blade_custom:OnRefresh( kv )
    if not IsServer() then return end
    -- references
    self.damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
    local interval = 1

    -- Start interval
    self:StartIntervalThink( interval )

    -- Play effects
    self:PlayEffects()
end

function modifier_doom_infernal_blade_custom:OnRemoved()
end

function modifier_doom_infernal_blade_custom:OnDestroy()
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_doom_infernal_blade_custom:OnIntervalThink()
    -- apply damage
    ApplyDamage( self.damageTable )
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_doom_infernal_blade_custom:GetEffectName()
    return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf"
end

function modifier_doom_infernal_blade_custom:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_doom_infernal_blade_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_impact.vpcf"
    local sound_cast = "Hero_DoomBringer.InfernalBlade.Target"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
end

function modifier_doom_infernal_blade_custom:PlayEffects2()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_doom_bringer/doom_bringer_shard_bonus.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 1, self:GetParent():GetAbsOrigin() )
    ParticleManager:SetParticleControl( effect_cast, 2, self:GetParent():GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end