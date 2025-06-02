LinkLuaModifier("modifier_talent_bloodseeker_2", "heroes/hero_bloodseeker/talents/talent_bloodseeker_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_bloodseeker_2_buff", "heroes/hero_bloodseeker/talents/talent_bloodseeker_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

talent_bloodseeker_2 = class(ItemBaseClass)
modifier_talent_bloodseeker_2 = class(talent_bloodseeker_2)
modifier_talent_bloodseeker_2_buff = class(ItemBaseClassBuff)
-------------
function talent_bloodseeker_2:GetIntrinsicModifierName()
    return "modifier_talent_bloodseeker_2"
end
-------------
function modifier_talent_bloodseeker_2:OnCreated()
end

function modifier_talent_bloodseeker_2:OnDestroy()
end

function modifier_talent_bloodseeker_2:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_talent_bloodseeker_2:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if not parent:HasModifier("modifier_bloodseeker_bloodrage_custom_buff") then return end

    local ability = self:GetAbility()

    if not ability or (ability ~= nil and ability:GetLevel() < 3) then return end

    local buff = parent:FindModifierByName("modifier_talent_bloodseeker_2_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_talent_bloodseeker_2_buff", {
            duration = ability:GetSpecialValueFor("stack_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
--------
function modifier_talent_bloodseeker_2_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE 
    }
end

function modifier_talent_bloodseeker_2_buff:GetModifierExtraHealthPercentage()
    return self:GetAbility():GetSpecialValueFor("health_increase_pct") * self:GetStackCount()
end

function modifier_talent_bloodseeker_2_buff:GetTexture()
    return "bloodseeker_bloodrage"
end