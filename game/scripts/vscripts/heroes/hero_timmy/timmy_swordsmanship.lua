LinkLuaModifier("modifier_timmy_swordsmanship", "heroes/hero_timmy/timmy_swordsmanship", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_timmy_swordsmanship_buff", "heroes/hero_timmy/timmy_swordsmanship", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

timmy_swordsmanship = class(ItemBaseClass)
modifier_timmy_swordsmanship = class(timmy_swordsmanship)
modifier_timmy_swordsmanship_buff = class(ItemBaseClassBuff)
-------------
function timmy_swordsmanship:GetIntrinsicModifierName()
    return "modifier_timmy_swordsmanship"
end
------------
function modifier_timmy_swordsmanship:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_timmy_swordsmanship:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end

    local victim = event.unit 

    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end

    local buff = parent:FindModifierByName("modifier_timmy_swordsmanship_buff")
    if not buff then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_timmy_swordsmanship_buff", {})
    end

    if buff then
        buff:IncrementStackCount()
        buff:ForceRefresh()
    end
end
-------------
function modifier_timmy_swordsmanship_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_timmy_swordsmanship_buff:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("damage_per_kill") * self:GetStackCount()
end