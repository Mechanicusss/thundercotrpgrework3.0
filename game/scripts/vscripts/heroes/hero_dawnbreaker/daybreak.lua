LinkLuaModifier("modifier_dawnbreaker_daybreak", "heroes/hero_dawnbreaker/daybreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_daybreak_active", "heroes/hero_dawnbreaker/daybreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_daybreak_active_buff", "heroes/hero_dawnbreaker/daybreak", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dawnbreaker_daybreak_active_buff_enemy_debuff", "heroes/hero_dawnbreaker/daybreak", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassActive = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

dawnbreaker_daybreak = class(ItemBaseClass)
modifier_dawnbreaker_daybreak = class(dawnbreaker_daybreak)
modifier_dawnbreaker_daybreak_active = class(ItemBaseClassActive)
modifier_dawnbreaker_daybreak_active_buff = class(ItemBaseClassActive)
modifier_dawnbreaker_daybreak_active_buff_enemy_debuff = class(ItemBaseClassDebuff)
-------------
function dawnbreaker_daybreak:GetIntrinsicModifierName()
    return "modifier_dawnbreaker_daybreak"
end

function dawnbreaker_daybreak:Precache(context)
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreak_buff/dawnbreaker_daybreak_buff.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreak_buff/dawnbreaker_daybreak_buff_beam_shaft.vpcf", context )
    PrecacheResource( "particle", "particles/dawnbreaker/dawnbreak_buff/dawnbreaker_daybreak_buff_outer.vpcf", context )
end

function dawnbreaker_daybreak:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_dawnbreaker_daybreak_active", { 
        duration = self:GetSpecialValueFor("duration"), 
        oldTime = GameRules:GetTimeOfDay() 
    })
end
------------
function modifier_dawnbreaker_daybreak:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    if not parent:IsRealHero() or parent:IsIllusion() then return end

    self.starbreakerImmunity = false

    self:StartIntervalThink(0.1)
end

function modifier_dawnbreaker_daybreak:CheckState()
    local state = {}

    if self.starbreakerImmunity then
        state[MODIFIER_STATE_INVULNERABLE] = true
    end

    return state
end

function modifier_dawnbreaker_daybreak:OnIntervalThink()
    local parent = self:GetParent()
    if not parent:IsRealHero() or parent:IsIllusion() then return end

    if GameRules:IsDaytime() then 
        if not parent:HasModifier("modifier_dawnbreaker_daybreak_active_buff") then
            parent:AddNewModifier(parent, self:GetAbility(), "modifier_dawnbreaker_daybreak_active_buff", {})
        end
    else
        if parent:HasModifier("modifier_dawnbreaker_daybreak_active_buff") then
            parent:RemoveModifierByNameAndCaster("modifier_dawnbreaker_daybreak_active_buff", parent)
        end
    end

    if parent:HasModifier("modifier_dawnbreaker_daybreak_active_buff") then
        if parent:HasModifier("modifier_dawnbreaker_fire_wreath_caster") then
            self.starbreakerImmunity = true
        elseif not parent:HasModifier("modifier_dawnbreaker_fire_wreath_caster") and self.starbreakerImmunity then
            self.starbreakerImmunity = false
        end
    end
end
------------
function modifier_dawnbreaker_daybreak_active:DeclareFunctions()
    local funcs = {
        
    }

    return funcs
end

function modifier_dawnbreaker_daybreak_active:OnCreated(params)
    if not IsServer() then return end

    self.oldTime = params.oldTime

    GameRules:SetTimeOfDay(0.30)
    GameRules:GetGameModeEntity():SetDaynightCycleDisabled(true)
end

function modifier_dawnbreaker_daybreak_active:OnDestroy()
    if not IsServer() then return end

    GameRules:SetTimeOfDay(self.oldTime)
    GameRules:GetGameModeEntity():SetDaynightCycleDisabled(false)
end
--------
function modifier_dawnbreaker_daybreak_active_buff_enemy_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
    return funcs
end

function modifier_dawnbreaker_daybreak_active_buff_enemy_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_dawnbreaker_daybreak_active_buff_enemy_debuff:GetModifierIncomingDamage_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("debuff_damage_increase_pct", (self:GetAbility():GetLevel() - 1)) * self:GetStackCount()
end
--------
function modifier_dawnbreaker_daybreak_active_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE, --GetModifierHealAmplify_PercentageSource
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
    return funcs
end

function modifier_dawnbreaker_daybreak_active_buff:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local victim = event.unit

    if parent ~= event.attacker then return end
    if not parent:HasScepter() then return end
    if event.inflictor == nil then return end
    if not victim:IsAlive() then return end

    local debuffName = "modifier_dawnbreaker_daybreak_active_buff_enemy_debuff"
    local debuffDuration = self:GetAbility():GetSpecialValueFor("debuff_duration")
    local maxStacks = self:GetAbility():GetSpecialValueFor("debuff_max_stacks")

    if not victim:HasModifier(debuffName) then
        local scorch = victim:AddNewModifier(parent, self:GetAbility(), debuffName, { 
            duration = debuffDuration
        })

        scorch:SetStackCount(1)
    else
        local debuff = victim:FindModifierByNameAndCaster(debuffName, parent)
        if debuff:GetStackCount() < maxStacks then debuff:IncrementStackCount() end
        
        debuff:ForceRefresh()
    end
end

function modifier_dawnbreaker_daybreak_active_buff:GetModifierHealAmplify_PercentageSource()
    return self:GetAbility():GetLevelSpecialValueFor("heal_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_dawnbreaker_daybreak_active_buff:GetModifierHPRegenAmplify_Percentage()
    return self:GetAbility():GetLevelSpecialValueFor("heal_amp", (self:GetAbility():GetLevel() - 1))
end

function modifier_dawnbreaker_daybreak_active_buff:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local ability = caster:FindAbilityByName("dawnbreaker_luminosity_custom")

    if ability then
        local oldLuminosityMod = caster:FindModifierByName("modifier_dawnbreaker_luminosity_custom")
        if oldLuminosityMod ~= nil then caster:RemoveModifierByName("modifier_dawnbreaker_luminosity_custom") end

        ability:SetLevel(0)

        local daybreakLumi = caster:FindAbilityByName("dawnbreaker_luminosity_custom_daybreak")
        if daybreakLumi then daybreakLumi:SetLevel(1) caster:AddNewModifier(caster, daybreakLumi, "modifier_dawnbreaker_luminosity_custom", {}) end

        caster:SwapAbilities(
            "dawnbreaker_luminosity_custom",
            "dawnbreaker_luminosity_custom_daybreak",
            false,
            true
        )
    end
    ---
    -- Particle --
    --
    -- Particle --
    self.vfx = ParticleManager:CreateParticle("particles/dawnbreaker/dawnbreak_buff/dawnbreaker_daybreak_buff.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl( self.vfx, 0, caster:GetOrigin() )
    ParticleManager:SetParticleControl( self.vfx, 1, caster:GetOrigin() )

    EmitSoundOnLocationWithCaster(caster:GetOrigin(), "Hero_Dawnbreaker.Solar_Guardian.Target.Layer", caster)
    --
end

function modifier_dawnbreaker_daybreak_active_buff:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local ability = caster:FindAbilityByName("dawnbreaker_luminosity_custom_daybreak")
    if ability then    
        local oldLuminosityMod = caster:FindModifierByName("modifier_dawnbreaker_luminosity_custom_daybreak")
        if oldLuminosityMod ~= nil then caster:FindModifierByName("modifier_dawnbreaker_luminosity_custom_daybreak") end

        ability:SetLevel(0)

        local Lumi = caster:FindAbilityByName("dawnbreaker_luminosity_custom")
        if Lumi then Lumi:SetLevel(1) caster:AddNewModifier(caster, Lumi, "modifier_dawnbreaker_luminosity_custom", {}) end

        caster:SwapAbilities(
            "dawnbreaker_luminosity_custom_daybreak",
            "dawnbreaker_luminosity_custom",
            false,
            true
        )
    end

    -- Particle --
    ParticleManager:DestroyParticle(self.vfx, true)
    ParticleManager:ReleaseParticleIndex(self.vfx)
end