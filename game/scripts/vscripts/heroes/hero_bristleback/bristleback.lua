bristleback_bristleback_custom = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_custom", "heroes/hero_bristleback/bristleback", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function bristleback_bristleback_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_bristleback_custom"
end

function bristleback_bristleback_custom:GetBehavior()
    local caster = self:GetCaster()
    if caster:HasScepter() then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    else
        return DOTA_ABILITY_BEHAVIOR_PASSIVE
    end
end

function bristleback_bristleback_custom:GetCooldown()
    local caster = self:GetCaster()
    if caster:HasScepter() then
        return self:GetSpecialValueFor("quill_procs_cd")
    else
        return 0
    end
end

function bristleback_bristleback_custom:GetManaCost()
    local caster = self:GetCaster()
    if caster:HasScepter() then
        return self:GetSpecialValueFor("quill_procs_mana_cost")
    else
        return 0
    end
end

function bristleback_bristleback_custom:OnSpellStart()
    if not IsServer() then return end 

    local caster = self:GetCaster()

    if not caster:HasScepter() then return end
    
    local quill = caster:FindAbilityByName("bristleback_quill_spray_custom")

    if not quill or (quill ~= nil and quill:GetLevel() < 1) then return end 

    local amount = self:GetSpecialValueFor("quill_procs")

    self.procs = 0

    Timers:CreateTimer(0.01, function()
        if not caster or caster:IsNull() then return end 
        if not caster:IsAlive() then return end
        if not caster:HasScepter() then return end
        if not quill or (quill ~= nil and quill:GetLevel() < 1) then return end 

        if self.procs >= amount then return end 

        SpellCaster:Cast(quill, caster, false)
        
        self.procs = self.procs + 1 

        return 0.2
    end)
end

modifier_bristleback_bristleback_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_bristleback_bristleback_custom:IsHidden()
    return true
end

function modifier_bristleback_bristleback_custom:IsDebuff()
    return false
end

function modifier_bristleback_bristleback_custom:IsPurgable()
    return false
end



--------------------------------------------------------------------------------
-- Initializations
function modifier_bristleback_bristleback_custom:OnCreated( kv )
    -- references
    self.reduction_back = self:GetAbility():GetSpecialValueFor( "back_damage_reduction" )
    self.reduction_side = self:GetAbility():GetSpecialValueFor( "side_damage_reduction" )
    self.angle_back = self:GetAbility():GetSpecialValueFor( "back_angle" )
    self.angle_side = self:GetAbility():GetSpecialValueFor( "side_angle" )
    self.max_threshold = self:GetAbility():GetSpecialValueFor( "quill_release_threshold" )
    self.max_quills = self:GetAbility():GetSpecialValueFor( "quill_release_threshold_max_quills" )
    self.ability_proc = "bristleback_quill_spray_custom"

    self.threshold = 0
    self.lastCastTime = 0
    self.castInterval = 0.1

    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    self:StartIntervalThink(self.castInterval)
end

function modifier_bristleback_bristleback_custom:OnRefresh( kv )
    -- references
    self.reduction_back = self:GetAbility():GetSpecialValueFor( "back_damage_reduction" )
    self.reduction_side = self:GetAbility():GetSpecialValueFor( "side_damage_reduction" )
    self.angle_back = self:GetAbility():GetSpecialValueFor( "back_angle" )
    self.angle_side = self:GetAbility():GetSpecialValueFor( "side_angle" )
    self.max_threshold = self:GetAbility():GetSpecialValueFor( "quill_release_threshold" )
    self.max_quills = self:GetAbility():GetSpecialValueFor( "quill_release_threshold_max_quills" )
end

function modifier_bristleback_bristleback_custom:OnRemoved( kv )
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_bristleback_bristleback_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        -- MODIFIER_EVENT_ON_TAKEDAMAGE,
    }

    return funcs
end

function modifier_bristleback_bristleback_custom:GetModifierIncomingDamage_Percentage( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local parent = self:GetParent()
        local attacker = params.attacker
        local reduction = 0

        local abilityName = self:GetName()

        _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
        _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

        _G.PlayerDamageReduction[self.accountID][abilityName] = 0
        self.num = 0

        if attacker:IsTower() then
            return 0
        end

        -- Check target position
        local facing_direction = parent:GetAnglesAsVector().y
        local attacker_vector = (attacker:GetOrigin() - parent:GetOrigin()):Normalized()
        local attacker_direction = VectorToAngles( attacker_vector ).y
        local angle_diff = AngleDiff( facing_direction, attacker_direction )
        angle_diff = math.abs(angle_diff)

        -- calculate damage reduction
        if angle_diff > (180-self.angle_back) then
            --reduction = self.reduction_back
            _G.PlayerDamageReduction[self.accountID][abilityName] = self.reduction_back
            --self:ThresholdLogic( params.damage )
            self.threshold = self.threshold + params.damage
            self:PlayEffects( true, attacker_vector )

        elseif angle_diff > (180-self.angle_side) then
            --reduction = self.reduction_side
            _G.PlayerDamageReduction[self.accountID][abilityName] = self.reduction_side
            self:PlayEffects( false, attacker_vector )
        else
            _G.PlayerDamageReduction[self.accountID][abilityName] = nil
        end
    end
end
--------------------------------------------------------------------------------
-- helper
function modifier_bristleback_bristleback_custom:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:IsAlive() then return end 
    
    local hpThreshold = parent:GetMaxHealth() * (self.max_threshold / 100)

    if self.threshold >= hpThreshold and GameRules:GetGameTime() - self.lastCastTime >= self.castInterval then
        local procs = math.floor(self.threshold / hpThreshold)
        if procs > self.max_quills then
            procs = self.max_quills
        end

        -- reset threshold
        self.threshold = self.threshold - (procs * hpThreshold)
        self.lastCastTime = GameRules:GetGameTime()

        -- cast quill spray if found
        local ability = parent:FindAbilityByName(self.ability_proc)
        if ability ~= nil and ability:GetLevel() >= 1 then
            for i = 1, procs, 1 do
                SpellCaster:Cast(ability, parent, false)
            end
        end
    end
end

function modifier_bristleback_bristleback_custom:ThresholdLogic( damage )
    self.threshold = self.threshold + damage

    local parent = self:GetParent()
    local hpThreshold = parent:GetMaxHealth()*(self.max_threshold/100)

    if self.threshold > hpThreshold then
        local procs = math.floor(self.threshold / hpThreshold)
        if procs > self.max_quills then
            procs = self.max_quills
        end
        
        -- reset threshold
        self.threshold = 0

        -- cast quill spray if found
        local ability = parent:FindAbilityByName( self.ability_proc )
        if ability~=nil and ability:GetLevel()>=1 then
            for i = 1, procs, 1 do
                SpellCaster:Cast(ability, parent, false)
            end
        end
    end
end
--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_bristleback_bristleback_custom:PlayEffects( bBack, direction )
    -- Get Resources
    local particle_cast_back = "particles/units/heroes/hero_bristleback/bristleback_back_dmg.vpcf"
    local particle_cast_side = "particles/units/heroes/hero_bristleback/bristleback_side_dmg.vpcf"
    local sound_cast = "Hero_Bristleback.Bristleback"

    local effect_cast = nil
    if bBack then
        effect_cast = ParticleManager:CreateParticle( particle_cast_back, PATTACH_ABSORIGIN, self:GetParent() )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            1,
            self:GetParent(),
            PATTACH_POINT_FOLLOW,
            "attach_hitloc",
            self:GetParent():GetOrigin(), -- unknown
            true -- unknown, true
        )
        EmitSoundOn( sound_cast, self:GetParent() )
    else
        effect_cast = ParticleManager:CreateParticle( particle_cast_side, PATTACH_ABSORIGIN, self:GetParent() )
        ParticleManager:SetParticleControlEnt(
            effect_cast,
            1,
            self:GetParent(),
            PATTACH_POINT_FOLLOW,
            "attach_hitloc",
            self:GetParent():GetOrigin(), -- unknown
            true -- unknown, true
        )
        ParticleManager:SetParticleControlForward( effect_cast, 3, -direction )

    end
    ParticleManager:ReleaseParticleIndex( effect_cast )
end