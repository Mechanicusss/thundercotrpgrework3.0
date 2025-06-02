LinkLuaModifier("modifier_sniper_long_range_advantage_custom", "heroes/hero_sniper/sniper_long_range_advantage_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sniper_long_range_advantage_custom_buff", "heroes/hero_sniper/sniper_long_range_advantage_custom", LUA_MODIFIER_MOTION_NONE)

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

sniper_long_range_advantage_custom = class(ItemBaseClass)
modifier_sniper_long_range_advantage_custom = class(sniper_long_range_advantage_custom)
modifier_sniper_long_range_advantage_custom_buff = class(ItemBaseClassBuff)
-------------
function sniper_long_range_advantage_custom:GetIntrinsicModifierName()
    return "modifier_sniper_long_range_advantage_custom"
end
---------
function modifier_sniper_long_range_advantage_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_sniper_long_range_advantage_custom:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.target = nil
end

function modifier_sniper_long_range_advantage_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local ability = self:GetAbility()

    local buff = parent:FindModifierByName("modifier_sniper_long_range_advantage_custom_buff")

    if self.target ~= event.target and buff ~= nil then
        self.target = nil
        buff:Destroy()
    end

    if not buff then
        buff = parent:AddNewModifier(parent, ability, "modifier_sniper_long_range_advantage_custom_buff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if buff then
        if buff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end

    self.target = event.target
end
---------
function modifier_sniper_long_range_advantage_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_sniper_long_range_advantage_custom_buff:GetModifierDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") * self:GetStackCount()
end