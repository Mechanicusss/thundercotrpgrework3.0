LinkLuaModifier("modifier_spectre_spectral_strike_custom", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_strike_custom_crit", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_strike_custom_debuff", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_strike_custom_fear", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spectre_spectral_strike_custom_counter", "heroes/hero_spectre/spectre_spectral_strike_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

spectre_spectral_strike_custom = class(ItemBaseClass)
modifier_spectre_spectral_strike_custom = class(spectre_spectral_strike_custom)
modifier_spectre_spectral_strike_custom_debuff = class(ItemBaseClassDebuff)
modifier_spectre_spectral_strike_custom_fear = class(ItemBaseClassDebuff)
modifier_spectre_spectral_strike_custom_crit = class(ItemBaseClassBuff)
modifier_spectre_spectral_strike_custom_counter = class(ItemBaseClassBuff)
-------------
function spectre_spectral_strike_custom:GetIntrinsicModifierName()
    return "modifier_spectre_spectral_strike_custom"
end

function modifier_spectre_spectral_strike_custom:GetPriority()
    return 999999
end

function modifier_spectre_spectral_strike_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE  
    }
end

function modifier_spectre_spectral_strike_custom:OnCreated()
    if not IsServer() then return end
end

function modifier_spectre_spectral_strike_custom:GetModifierDamageOutgoing_Percentage()
    return (self:GetAbility():GetSpecialValueFor("damage_from_attack_speed_pct")/100) * (self:GetParent():GetAttackSpeed()*100)
end

function modifier_spectre_spectral_strike_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if parent:HasModifier("modifier_spectre_spectral_strike_custom_crit") then return end

    local ability = self:GetAbility()
    local nthHit = ability:GetSpecialValueFor("nth_attack")

    if parent:HasScepter() then
        nthHit = ability:GetSpecialValueFor("nth_attack_scepter")
    end

    local counter = parent:FindModifierByName("modifier_spectre_spectral_strike_custom_counter")
    if not counter then
        counter = parent:AddNewModifier(parent, ability, "modifier_spectre_spectral_strike_custom_counter", {})
    end

    if counter then
        if counter:GetStackCount() < nthHit then
            counter:IncrementStackCount()
        end

        if counter:GetStackCount() >= nthHit then
            counter:Destroy()
            
            parent:AddNewModifier(
                parent,
                ability,
                "modifier_spectre_spectral_strike_custom_crit",
                {}
            )
        end
    end
end

function modifier_spectre_spectral_strike_custom:GetModifierFixedAttackRate()
    return self:GetAbility():GetSpecialValueFor("fixed_attack_rate")
end
---------------
function modifier_spectre_spectral_strike_custom_crit:PlayEffects( target )
    -- Load effects
    local particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
    local sound_cast = "Hero_PhantomAssassin.CoupDeGrace"

    -- if target:IsMechanical() then
    --  particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact_mechanical.vpcf"
    --  sound_cast = "Hero_PhantomAssassin.CoupDeGrace.Mech"
    -- end

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        target:GetOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlForward( effect_cast, 1, (self:GetParent():GetOrigin()-target:GetOrigin()):Normalized() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    EmitSoundOn( sound_cast, target )
end

function modifier_spectre_spectral_strike_custom_crit:OnCreated()
    if not IsServer() then return end

    self.struck = false
end

function modifier_spectre_spectral_strike_custom_crit:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_spectre_spectral_strike_custom_crit:GetModifierPreAttack_CriticalStrike(event)
    if IsServer() and (not self:GetParent():PassivesDisabled()) and not self.struck then
        self.record = event.record

        return self:GetAbility():GetSpecialValueFor("critical_damage")
    end
end

function modifier_spectre_spectral_strike_custom_crit:GetModifierProcAttack_Feedback()
    if IsServer() then
        if self.record and not self.struck then
            self.record = nil
        end
    end
end

function modifier_spectre_spectral_strike_custom_crit:OnAttackLanded(event)
    local parent = self:GetParent()

    if parent ~= event.attacker then return end
    if self.struck then return end

    local ability = self:GetAbility()

    self:PlayEffects(event.target)

    self.struck = true

    local debuff = event.target:AddNewModifier(
        parent,
        ability,
        "modifier_spectre_spectral_strike_custom_debuff",
        {
            duration = ability:GetSpecialValueFor("duration"),
            damage = event.damage
        }
    )

    Timers:CreateTimer(0.1, function()
        if not self:IsNull() then
            self:Destroy()
        end
    end)
end
--------------
function modifier_spectre_spectral_strike_custom_debuff:OnCreated(params)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()

    if caster:IsIllusion() then
        caster = caster:GetOwner():GetAssignedHero()
    end

    self.damage = params.damage * (ability:GetSpecialValueFor("bleed_pct")/100)

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage = self.damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = ability
    }

    local interval = ability:GetSpecialValueFor("interval")

    self:OnIntervalThink()
    self:StartIntervalThink(interval)
end

function modifier_spectre_spectral_strike_custom_debuff:OnIntervalThink()
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, self:GetParent(), self.damage, nil)
    ApplyDamage(self.damageTable)
end

function modifier_spectre_spectral_strike_custom_debuff:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end

function modifier_spectre_spectral_strike_custom_debuff:IsStackable()
    return true
end

function modifier_spectre_spectral_strike_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end