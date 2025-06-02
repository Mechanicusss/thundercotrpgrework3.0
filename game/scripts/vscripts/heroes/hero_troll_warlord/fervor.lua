fervor_custom = class({})
modifier_fervor_custom_effect_decay = class({})

LinkLuaModifier("modifier_fervor_custom", 'heroes/hero_troll_warlord/fervor', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fervor_custom_effect", 'heroes/hero_troll_warlord/fervor', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_fervor_custom_effect_decay", 'heroes/hero_troll_warlord/fervor', LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
function fervor_custom:GetIntrinsicModifierName()
    return "modifier_fervor_custom"
end

modifier_fervor_custom = class({})

-----------------------------------------------------------------------------
function modifier_fervor_custom:IsHidden()
    return true
end

--------------------------------------------------------------------------------
function modifier_fervor_custom:IsPurgable()
    return false
end

--------------------------------------------------------------------------------
function modifier_fervor_custom_effect_decay:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()

    self.removalTimer = nil

    self.gracePeriod = ability:GetSpecialValueFor("grace_period")
    if parent:HasTalent("special_bonus_unique_troll_warlord_1_custom") then
        self.gracePeriod  = self.gracePeriod  + parent:FindAbilityByName("special_bonus_unique_troll_warlord_1_custom"):GetSpecialValueFor("value")
    end

    self:StartIntervalThink(self.gracePeriod)
end

function modifier_fervor_custom_effect_decay:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local fervor = parent:FindModifierByName("modifier_fervor_custom_effect")
    if fervor == nil then return end
    if self.removalTimer ~= nil then return end

    self.removalTimer = Timers:CreateTimer(0.5, function()
        if not parent:HasModifier("modifier_fervor_custom_effect_decay") then
            Timers:RemoveTimer(self.removalTimer)
            self.removalTimer = nil
            return
        end

        local loss = ability:GetSpecialValueFor("stack_loss_pct")
        local minLoss = ability:GetSpecialValueFor("min_stack_loss")
        local stackCount = fervor:GetStackCount()

        local removedStacks = stackCount * (loss/100) * 0.5
        if removedStacks < minLoss then
            removedStacks = minLoss
        end

        if parent:HasModifier("modifier_spawn_healing_aura") then
            removedStacks = 0
        end

        local newStacks = stackCount - removedStacks
        if newStacks < 1 then
            newStacks = 0
        end

        fervor:SetStackCount(newStacks)

        return 0.5
    end)
end
--------------------------------------------------------------------------------
function modifier_fervor_custom:OnCreated(kv)
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
    self.target = nil

    if IsServer() then
        self.graceTimer = nil
        self:StartIntervalThink(0.5)
    end
end

function modifier_fervor_custom:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local gracePeriod = ability:GetSpecialValueFor("grace_period")
    if parent:HasTalent("special_bonus_unique_troll_warlord_1_custom") then
        gracePeriod = gracePeriod  + parent:FindAbilityByName("special_bonus_unique_troll_warlord_1_custom"):GetSpecialValueFor("value")
    end

    local fervor = parent:FindModifierByName("modifier_fervor_custom_effect")
    if fervor ~= nil then
        if not parent:HasModifier("modifier_fervor_custom_effect_decay") and self.graceTimer == nil then
            self.graceTimer = Timers:CreateTimer(gracePeriod, function()
                parent:AddNewModifier(parent, ability, "modifier_fervor_custom_effect_decay", {})

                self.graceTimer = nil
            end)
        end
    end
end
-------------------------------------------------------------------------------
function modifier_fervor_custom:OnRefresh(kv)
    self.duration = self:GetAbility():GetSpecialValueFor("duration")
end

-------------------------------------------------------------------------------
function modifier_fervor_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
        MODIFIER_EVENT_ON_ATTACK,
    }
    return funcs
end

-------------------------------------------------------------------------------
function modifier_fervor_custom:OnAttack(params)
    if not IsServer() then return end

    if params.attacker ~= self:GetParent() then return end

    if params.attacker:HasModifier("modifier_fervor_custom_effect_decay") then
        params.attacker:RemoveModifierByName("modifier_fervor_custom_effect_decay")
    end
end

function modifier_fervor_custom:GetModifierProcAttack_Feedback(params)
    local parent = self:GetParent()
    if not parent or parent:PassivesDisabled() then return end
    if not IsServer() then return end
    
    if parent:IsIllusion() then return end
    if params.target:GetTeamNumber() == parent:GetTeamNumber() then return end

    parent:AddNewModifier(parent, self:GetAbility(), "modifier_fervor_custom_effect", {})
    local stack_count = params.attacker:GetModifierStackCount("modifier_fervor_custom_effect", parent)

    if params.target:GetUnitName() == "npc_dota_creature_target_dummy" then 
        self:SetStacksCustom(stack_count) 
        return false 
    end

    if not parent:HasModifier("modifier_item_aghanims_shard") then
        if stack_count < self:GetAbility():GetSpecialValueFor("max_stacks") then
            self:SetStacksCustom(stack_count + 1)
        end
    else
        self:SetStacksCustom(stack_count + 1)
    end
    
    --[[
    if self.target == params.target then
        self:SetStacksCustom(stack_count + 1)
    else
        self:SetStacksCustom(1)
    end
    self.target = params.target
    --]]
end
-------------------------------------------------------------------------------
function modifier_fervor_custom:SetStacksCustom(value)
    local attacker = self:GetParent()

    --if not self:GetAbility():IsCooldownReady() then return end

    attacker:SetModifierStackCount("modifier_fervor_custom_effect", attacker, value)

    --self:GetAbility():UseResources(false,false,true)
end

modifier_fervor_custom_effect = class({})

--------------------------------------------------------------------------------

function modifier_fervor_custom_effect:IsHidden()
    return false
end

--------------------------------------------------------------------------------

function modifier_fervor_custom_effect:DestroyOnExpire()
    return false
end

--------------------------------------------------------------------------------
function modifier_fervor_custom_effect:IsPurgable()
    return false
end

--------------------------------------------------------------------------------

function modifier_fervor_custom_effect:IsDebuff()
    return false
end

function modifier_fervor_custom_effect:RemoveOnDeath()
    return true
end

--------------------------------------------------------------------------------

function modifier_fervor_custom_effect:OnCreated( kv )
    self:SetHasCustomTransmitterData(true)
    self.damage = self:GetAbility():GetSpecialValueFor( "damage" )
    self.attack_speed = self:GetAbility():GetSpecialValueFor( "attack_speed" )

    if not IsServer() then return end
    --self:GetCaster():GetTalentSpecialValueFor("special_bonus_unique_troll_warlord_5")
    self.attack_speed_by_talent = 0
    self:InvokeBonusAttackSpeed()
end

function modifier_fervor_custom_effect:AddCustomTransmitterData()
    return
    {
        attack_speed_by_talent = self.fAttack_speed_by_talent,
    }
end

function modifier_fervor_custom_effect:HandleCustomTransmitterData(data)
    if data.attack_speed_by_talent ~= nil then
        self.fAttack_speed_by_talent = tonumber(data.attack_speed_by_talent)
    end
end

function modifier_fervor_custom_effect:InvokeBonusAttackSpeed()
    if IsServer() == true then
        self.fAttack_speed_by_talent = self.attack_speed_by_talent

        self:SendBuffRefreshToClients()
    end
end

--------------------------------------------------------------------------------
function modifier_fervor_custom_effect:OnRefresh(kv)
    self:OnCreated(kv)
end
-------------------------------------------------------------------------------

function modifier_fervor_custom_effect:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    }
    return funcs
end

--------------------------------------------------------------------------------

function modifier_fervor_custom_effect:GetModifierPreAttack_BonusDamage( params )
    return self.damage * self:GetStackCount()
end

--------------------------------------------------------------------------------
function modifier_fervor_custom_effect:GetModifierAttackSpeedBonus_Constant( params )
    return (self.attack_speed + self.fAttack_speed_by_talent) * self:GetStackCount()
end
--
function modifier_fervor_custom_effect_decay:IsDebuff()
    return true
end

function modifier_fervor_custom_effect_decay:IsHidden()
    return true
end

function modifier_fervor_custom_effect_decay:RemoveOnDeath()
    return true
end