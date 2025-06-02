LinkLuaModifier("modifier_max_movement_speed", "modifiers/modifier_max_movement_speed", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
}

max_movement_speed = class(ItemBaseClass)
modifier_max_movement_speed = class(max_movement_speed)

-----------------
function max_movement_speed:GetIntrinsicModifierName()
    return "modifier_max_movement_speed"
end
-----------------
function modifier_max_movement_speed:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
        MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    }

    return funcs
end

function modifier_max_movement_speed:GetModifierMoveSpeed_Limit()
    local caster = self:GetCaster()

    if not caster:HasModifier("modifier_xp_agility_talent_9") and not caster:HasModifier("modifier_centaur_stampede_custom_buff") then
        if caster:HasModifier("modifier_spirit_breaker_charge_of_darkness") then
            return 999999
        elseif caster:GetUnitName() == "npc_dota_hero_spirit_breaker" then
            return 900
        elseif caster:HasModifier("modifier_spectre_spectral_nemesis_custom_illusion") or caster:HasModifier("modifier_spectre_reality_custom_illusion") then
            return 2000
        else 
            return 900
        end
    end
end

function modifier_max_movement_speed:GetModifierIgnoreMovespeedLimit()
    return 1
end
