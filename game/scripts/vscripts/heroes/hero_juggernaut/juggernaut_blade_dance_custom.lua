juggernaut_blade_dance_custom = class({})
LinkLuaModifier( "modifier_juggernaut_blade_dance_custom", "heroes/hero_juggernaut/juggernaut_blade_dance_custom", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_juggernaut_blade_dance_custom_agility_boost", "heroes/hero_juggernaut/juggernaut_blade_dance_custom", LUA_MODIFIER_MOTION_NONE )

local BaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

local BaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_juggernaut_blade_dance_custom_agility_boost = class(BaseClassBuff)

--------------------------------------------------------------------------------
-- Passive Modifier
function juggernaut_blade_dance_custom:GetIntrinsicModifierName()
    return "modifier_juggernaut_blade_dance_custom"
end

modifier_juggernaut_blade_dance_custom = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_juggernaut_blade_dance_custom:IsHidden()
    -- actual true
    return true
end

function modifier_juggernaut_blade_dance_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_juggernaut_blade_dance_custom:OnCreated( kv )
    -- references
    self.crit_chance = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_chance" )
    self.crit_bonus = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_mult" )
    self.parent = self:GetParent()
    self.ability = self:GetAbility()
end

function modifier_juggernaut_blade_dance_custom:OnRefresh( kv )
    -- references
    self.crit_chance = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_chance" )
    self.crit_bonus = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_mult" )
end

function modifier_juggernaut_blade_dance_custom:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_juggernaut_blade_dance_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }

    return funcs
end

function modifier_juggernaut_blade_dance_custom:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        self.crit_chance = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_chance" )
        self.crit_bonus = self:GetAbility():GetSpecialValueFor( "blade_dance_crit_mult" )

        local cc = self.crit_chance
        local maxStacks = self:GetAbility():GetSpecialValueFor("max_stacks")

        if self:GetCaster():HasTalent("special_bonus_unique_juggernaut_2_custom") then
            cc = cc + self:GetCaster():FindAbilityByName("special_bonus_unique_juggernaut_2_custom"):GetSpecialValueFor("value")
        end

        if self:GetCaster():HasTalent("special_bonus_unique_juggernaut_3_custom") then
            maxStacks = maxStacks + self:GetCaster():FindAbilityByName("special_bonus_unique_juggernaut_3_custom"):GetSpecialValueFor("value")
        end

        if self:RollChance(cc) then
            self.record = params.record

            -- Add agility bonus --
            local parent = self:GetParent()

            local duration = self:GetAbility():GetSpecialValueFor("duration")

            if parent:HasTalent("special_bonus_unique_juggernaut_8_custom") then
                duration = duration + parent:FindAbilityByName("special_bonus_unique_juggernaut_8_custom"):GetSpecialValueFor("value")
            end

            local buff = parent:FindModifierByName("modifier_juggernaut_blade_dance_custom_agility_boost")
            if not buff then
                buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_juggernaut_blade_dance_custom_agility_boost", {
                    duration = duration
                })
            end

            if buff then
                if buff:GetStackCount() < maxStacks then
                    buff:IncrementStackCount()
                end

                buff:ForceRefresh()
            end

            return self.crit_bonus
        end
    end
end

function modifier_juggernaut_blade_dance_custom:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            self.record = nil
            
            EmitSoundOn("Hero_Juggernaut.BladeDance", params.target)

            local particleID = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_crit_tgt.vpcf", PATTACH_CUSTOMORIGIN, params.target)
            ParticleManager:SetParticleControlEnt(particleID, 0, params.target, PATTACH_POINT_FOLLOW, "attach_hitloc", params.target:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(particleID, 1, params.target, PATTACH_POINT_FOLLOW, "attach_hitloc", params.target:GetAbsOrigin(), true)
            ParticleManager:ReleaseParticleIndex(particleID)
        end
    end
end
--------------------------------------------------------------------------------
-- Helper
function modifier_juggernaut_blade_dance_custom:RollChance( chance )
    local rand = math.random()
    if rand<chance/100 then
        return true
    end
    return false
end
---------------
function modifier_juggernaut_blade_dance_custom_agility_boost:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS 
    }
end

function modifier_juggernaut_blade_dance_custom_agility_boost:GetModifierBonusStats_Agility()
    return self.fTotal
end

function modifier_juggernaut_blade_dance_custom_agility_boost:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.total = 0

    self:StartIntervalThink(0.1)
end

function modifier_juggernaut_blade_dance_custom_agility_boost:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.total = (parent:GetBaseAgility() * (ability:GetSpecialValueFor("agility_per_stack_pct")/100)) * self:GetStackCount()

    self:InvokeBonus()
end

function modifier_juggernaut_blade_dance_custom_agility_boost:OnIntervalThink()
    self:OnRefresh()
end

function modifier_juggernaut_blade_dance_custom_agility_boost:AddCustomTransmitterData()
    return
    {
        total = self.fTotal,
    }
end

function modifier_juggernaut_blade_dance_custom_agility_boost:HandleCustomTransmitterData(data)
    if data.total ~= nil then
        self.fTotal = tonumber(data.total)
    end
end

function modifier_juggernaut_blade_dance_custom_agility_boost:InvokeBonus()
    if IsServer() == true then
        self.fTotal = self.total

        self:SendBuffRefreshToClients()
    end
end