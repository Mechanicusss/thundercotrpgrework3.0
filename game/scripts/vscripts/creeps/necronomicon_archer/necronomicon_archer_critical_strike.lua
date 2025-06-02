LinkLuaModifier("modifier_necronomicon_archer_critical_strike", "creeps/necronomicon_archer/necronomicon_archer_critical_strike", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

necronomicon_archer_critical_strike = class(ItemBaseClass)
modifier_necronomicon_archer_critical_strike = class(necronomicon_archer_critical_strike)
-------------
function necronomicon_archer_critical_strike:GetIntrinsicModifierName()
    return "modifier_necronomicon_archer_critical_strike"
end

function modifier_necronomicon_archer_critical_strike:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
        MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
    }
    return funcs
end

function modifier_necronomicon_archer_critical_strike:GetModifierPreAttack_CriticalStrike( params )
    if IsServer() and (not self:GetParent():PassivesDisabled()) then
        local cc = self:GetAbility():GetSpecialValueFor("crit_chance")

        if RollPercentage(cc) then
            self.record = params.record

            return self:GetAbility():GetSpecialValueFor("crit_damage")
        end
    end
end

function modifier_necronomicon_archer_critical_strike:GetModifierProcAttack_Feedback( params )
    if IsServer() then
        if self.record then
            params.target:EmitSound("DOTA_Item.Daedelus.Crit")
            self.record = nil
        end
    end
end