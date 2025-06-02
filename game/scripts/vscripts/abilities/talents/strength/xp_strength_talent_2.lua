LinkLuaModifier("modifier_xp_strength_talent_2", "abilities/talents/strength/xp_strength_talent_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_strength_talent_2 = class(ItemBaseClass)
modifier_xp_strength_talent_2 = class(xp_strength_talent_2)
-------------
function xp_strength_talent_2:GetIntrinsicModifierName()
    return "modifier_xp_strength_talent_2"
end
-------------
function modifier_xp_strength_talent_2:OnCreated()
end

function modifier_xp_strength_talent_2:OnDestroy()
end

function modifier_xp_strength_talent_2:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL   
    }
end

function modifier_xp_strength_talent_2:GetModifierProcAttack_BonusDamage_Physical(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local victim = event.target

    if parent ~= event.attacker or parent == victim then return end 

    if not IsCreepTCOTRPG(victim) and not IsBossTCOTRPG(victim) then return end 

    local damage = parent:GetStrength() * (2.5/100) * self:GetStackCount()

    return damage
end