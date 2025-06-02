axe_counter_helix_custom = class({})
LinkLuaModifier( "modifier_axe_counter_helix_custom", "heroes/hero_axe/axe_counter_helix_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_counter_helix_custom_toggle", "heroes/hero_axe/axe_counter_helix_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_counter_helix_custom_thinker", "heroes/hero_axe/axe_counter_helix_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_axe_counter_helix_custom_thinker_aura", "heroes/hero_axe/axe_counter_helix_custom", LUA_MODIFIER_MOTION_NONE )

local ItemBaseClassToggle = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_axe_counter_helix_custom_toggle = class(ItemBaseClassToggle)
modifier_axe_counter_helix_custom_thinker = class(ItemBaseClassToggle)
modifier_axe_counter_helix_custom_thinker_aura = class(ItemBaseClassToggle)
--------------------------------------------------------------------------------
-- Passive Modifier
function axe_counter_helix_custom:GetIntrinsicModifierName()
    return "modifier_axe_counter_helix_custom"
end

function axe_counter_helix_custom:OnToggle()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local mod = "modifier_axe_counter_helix_custom_toggle"

    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, mod, {})
    else
        caster:RemoveModifierByName(mod)
    end
end

function axe_counter_helix_custom:GetBehavior()
    local caster = self:GetCaster()
    local runeCounterHelix = caster:HasModifier("modifier_item_socket_rune_legendary_axe_counter_helix")
    if runeCounterHelix then
        return DOTA_ABILITY_BEHAVIOR_TOGGLE
    end

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function axe_counter_helix_custom:GetManaCost()
    local caster = self:GetCaster()
    local runeCounterHelix = caster:HasModifier("modifier_item_socket_rune_legendary_axe_counter_helix")
    if runeCounterHelix then
        return caster:GetMaxMana() * (5/100)
    end

    return 0
end

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

modifier_axe_counter_helix_custom = class({})
--------------------------------------------------------------------------------
-- Classifications
function modifier_axe_counter_helix_custom:IsHidden()
    return true
end

function modifier_axe_counter_helix_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_axe_counter_helix_custom:OnCreated( kv )
end

function modifier_axe_counter_helix_custom:OnRefresh( kv )
end

function modifier_axe_counter_helix_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_axe_counter_helix_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    }

    return funcs
end

function modifier_axe_counter_helix_custom:OnAttackLanded( params )
    if IsServer() then
        if self:GetParent():HasModifier("modifier_axe_counter_helix_custom_toggle") then return end 

        if not self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
            if params.target ~= self:GetCaster() then return end

            if not IsCreepTCOTRPG(params.attacker) and not IsBossTCOTRPG(params.attacker) then return end
        else
            if params.attacker ~= self:GetCaster() and params.target ~= self:GetCaster() then return end
        end

        if self:GetCaster():PassivesDisabled() then return end

        if params.attacker:GetTeamNumber() == params.target:GetTeamNumber() then return end

        if params.attacker:IsOther() or params.attacker:IsBuilding() then return end

        if params.attacker:IsIllusion() then return end

        -- roll dice
        if not RollPercentage(self:GetAbility():GetSpecialValueFor( "trigger_chance" )) then return end

        local damagePure = (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())*(self:GetAbility():GetSpecialValueFor("attack_damage_pct")/100))

        local damageTable = {
            -- victim = target,
            attacker = self:GetCaster(),
            damage = damagePure,
            damage_type = self:GetAbility():GetAbilityDamageType(),
            ability = self:GetAbility()
        }

        damageTable.damage = damagePure

        -- find enemies
        local enemies = FindUnitsInRadius(
            self:GetCaster():GetTeamNumber(),   -- int, your team number
            self:GetCaster():GetOrigin(),   -- point, center point
            nil,    -- handle, cacheUnit. (not known)
            self:GetAbility():GetSpecialValueFor("radius"),    -- float, radius. or use FIND_UNITS_EVERYWHERE
            DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
            DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
            0,  -- int, order filter
            false   -- bool, can grow cache
        )

        -- damage
        for _,enemy in pairs(enemies) do
            damageTable.victim = enemy

            ApplyDamage( damageTable )
        end

        -- cooldown
        --self:GetAbility():UseResources( false, false, true )

        -- effects
        self:PlayEffects()
    end
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_axe_counter_helix_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_axe/axe_counterhelix.vpcf"
    local sound_cast = "Hero_Axe.CounterHelix"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3)
end
----------
function modifier_axe_counter_helix_custom_toggle:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = true
    }
end

function modifier_axe_counter_helix_custom_toggle:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE
    }
end

function modifier_axe_counter_helix_custom_toggle:GetOverrideAnimationRate()
    return 2
end

function modifier_axe_counter_helix_custom_toggle:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local runeCounterHelix = caster:FindModifierByName("modifier_item_socket_rune_legendary_axe_counter_helix")
    
    if not runeCounterHelix then return end 

    local interval = runeCounterHelix.interval

    self.cost = caster:GetMaxMana() * (runeCounterHelix.manaPerSec/100) * interval

    self.windCounter = 0

    self:StartIntervalThink(interval)
end

function modifier_axe_counter_helix_custom_toggle:OnIntervalThink()
    local caster = self:GetCaster()
    local runeCounterHelix = caster:FindModifierByName("modifier_item_socket_rune_legendary_axe_counter_helix")

    if (not runeCounterHelix) or self.cost > self:GetCaster():GetMana() then
        if self:GetAbility():GetToggleState() then
            self:GetAbility():ToggleAbility()
        end

        return 
    end 

    self.windCounter = self.windCounter + runeCounterHelix.interval

    local enemies = FindUnitsInRadius(
        self:GetCaster():GetTeamNumber(),   -- int, your team number
        self:GetCaster():GetOrigin(),   -- point, center point
        nil,    -- handle, cacheUnit. (not known)
        self:GetAbility():GetSpecialValueFor("radius"),    -- float, radius. or use FIND_UNITS_EVERYWHERE
        DOTA_UNIT_TARGET_TEAM_ENEMY,    -- int, team filter
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, -- int, type filter
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, -- int, flag filter
        0,  -- int, order filter
        false   -- bool, can grow cache
    )

    local damagePure = (self:GetCaster():GetAverageTrueAttackDamage(self:GetCaster())*(self:GetAbility():GetSpecialValueFor("attack_damage_pct")/100))

    local damageTable = {
        -- victim = target,
        attacker = self:GetCaster(),
        damage = damagePure,
        damage_type = self:GetAbility():GetAbilityDamageType(),
        ability = self:GetAbility()
    }

    -- damage
    for _,enemy in pairs(enemies) do
        damageTable.victim = enemy

        ApplyDamage( damageTable )
    end

    self:PlayEffects()

    self:GetCaster():SpendMana(self.cost, self:GetAbility())

    if self.windCounter >= 1 then
        --[[
        local windPos = caster:GetAbsOrigin()
        CreateModifierThinker(
            caster,
            self:GetAbility(),
            "modifier_axe_counter_helix_custom_thinker",
            { duration = talent:GetSpecialValueFor("wind_duration") },
            windPos,
            DOTA_TEAM_GOODGUYS,
            false
        )

        -- create vision
        AddFOWViewer(bit.bor(DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS), windPos, talent:GetSpecialValueFor("wind_radius"), talent:GetSpecialValueFor("wind_duration"), false)
        self.windCounter = 0
        --]]
    end
end

function modifier_axe_counter_helix_custom_toggle:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_axe/axe_counterhelix.vpcf"
    local sound_cast = "Hero_Axe.CounterHelix"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )
    self:GetParent():StartGesture(ACT_DOTA_CAST_ABILITY_3)
end
---------
function modifier_axe_counter_helix_custom_thinker:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    UTIL_Remove(parent)
end

function modifier_axe_counter_helix_custom_thinker:IsAura()
    return true
end

function modifier_axe_counter_helix_custom_thinker:GetAuraSearchType()
    return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_axe_counter_helix_custom_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_axe_counter_helix_custom_thinker:GetAuraRadius()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_axe_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        return talent:GetSpecialValueFor("wind_radius")
    end
end

function modifier_axe_counter_helix_custom_thinker:GetModifierAura()
    return "modifier_axe_counter_helix_custom_thinker_aura"
end

function modifier_axe_counter_helix_custom_thinker:GetAuraEntityReject(target)
    return false
end

function modifier_axe_counter_helix_custom_thinker:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_axe_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_gale_force_owner_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(self.vfx, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:SetParticleControl(self.vfx, 1, Vector(0, talent:GetSpecialValueFor("wind_radius"), 0))
    end

    self:StartIntervalThink(FrameTime())
end

function modifier_axe_counter_helix_custom_thinker:OnIntervalThink()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_axe_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 2) then
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end
  ------------
function modifier_axe_counter_helix_custom_thinker_aura:IsDebuff() return true end

function modifier_axe_counter_helix_custom_thinker_aura:OnCreated()
    if not IsServer() then return end 

    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_axe_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        self:StartIntervalThink(talent:GetSpecialValueFor("wind_interval"))
    end
end

function modifier_axe_counter_helix_custom_thinker_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_axe_1")
    if talent ~= nil and talent:GetLevel() > 1 then
        ApplyDamage({
            attacker = caster,
            victim = self:GetParent(),
            damage = talent:GetSpecialValueFor("wind_damage"),
            damage_type = DAMAGE_TYPE_MAGICAL,
            ability = self:GetAbility()
        })
    end
end

function modifier_axe_counter_helix_custom_thinker_aura:GetEffectName()
    return "particles/units/heroes/hero_windrunner/windrunner_gale_force_2.vpcf"
end