LinkLuaModifier("modifier_ursa_fury_swipes_custom", "heroes/hero_ursa/ursa_fury_swipes_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ursa_fury_swipes_custom_stack", "heroes/hero_ursa/ursa_fury_swipes_custom", LUA_MODIFIER_MOTION_NONE)

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

ursa_fury_swipes_custom = class(ItemBaseClass)
modifier_ursa_fury_swipes_custom = class(ursa_fury_swipes_custom)
modifier_ursa_fury_swipes_custom_stack = class(ItemBaseClassDebuff)
-------------
function ursa_fury_swipes_custom:GetIntrinsicModifierName()
    return "modifier_ursa_fury_swipes_custom"
end
---------
function modifier_ursa_fury_swipes_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_ursa_fury_swipes_custom:OnCreated()
    if not IsServer() then return end 

    self.hasOverpower = false
end

function modifier_ursa_fury_swipes_custom:GetModifierProcAttack_BonusDamage_Physical(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local stack = target:FindModifierByName("modifier_ursa_fury_swipes_custom_stack")
    if stack then
        local ability = self:GetAbility()
        local agiPerStack = parent:GetAgility() * (ability:GetSpecialValueFor("damage_from_agi_per_stack")/100)

        return stack:GetStackCount() * agiPerStack
    end
end

-- Note: You have to do it like this, otherwise it doesn't count the correct amount of stacks to add
-- with the bonus from Overpower
function modifier_ursa_fury_swipes_custom:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if parent:HasModifier("modifier_ursa_overpower_custom_buff") then
        self.hasOverpower = true
    end
end

function modifier_ursa_fury_swipes_custom:GetModifierTotalDamageOutgoing_Percentage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end 
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end

    self:FurySwipeLogic(target)

    local stack = target:FindModifierByName("modifier_ursa_fury_swipes_custom_stack")
    if stack then
        local ability = self:GetAbility()
        local multiplierPerStack = ability:GetSpecialValueFor("multiplier_per_stack")

        if not parent:HasModifier("modifier_ursa_overpower_custom_buff") then
            self.hasOverpower = false
        end

        return stack:GetStackCount() * multiplierPerStack
    end
end

function modifier_ursa_fury_swipes_custom:FurySwipeLogic(target)
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local duration = ability:GetSpecialValueFor("duration")
    local multiplierPerStack = ability:GetSpecialValueFor("multiplier_per_stack")
    local maxStacks = ability:GetSpecialValueFor("max_stacks")
    local stacksGainedPerHit = 1

    if self.hasOverpower then
        stacksGainedPerHit = stacksGainedPerHit + 1
    end

    if parent:HasModifier("modifier_ursa_enrage_custom_buff") then
        stacksGainedPerHit = stacksGainedPerHit * 2
    end

    local stack = target:FindModifierByName("modifier_ursa_fury_swipes_custom_stack")
    if not stack then
        stack = target:AddNewModifier(parent, ability, "modifier_ursa_fury_swipes_custom_stack", {
            duration = duration
        })
    end

    if stack then
        local stackCount = stack:GetStackCount()+stacksGainedPerHit

        if stackCount > maxStacks then
            stackCount = maxStacks
        end

        if stack:GetStackCount() < maxStacks then
            stack:SetStackCount(stackCount)
        end

        stack:ForceRefresh()
    end
end
----------
function modifier_ursa_fury_swipes_custom_stack:GetEffectName()
    return "particles/units/heroes/hero_ursa/ursa_fury_swipes_debuff.vpcf"
end

function modifier_ursa_fury_swipes_custom_stack:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end