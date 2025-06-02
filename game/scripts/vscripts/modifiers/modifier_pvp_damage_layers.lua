LinkLuaModifier("modifier_pvp_damage_layers", "modifiers/modifier_pvp_damage_layers", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
}

pvp_damage_layers = class(ItemBaseClass)
modifier_pvp_damage_layers = class(pvp_damage_layers)

function modifier_pvp_damage_layers:GetTexture() return "shield" end
-----------------
function pvp_damage_layers:GetIntrinsicModifierName()
    return "modifier_pvp_damage_layers"
end

function modifier_pvp_damage_layers:OnCreated()
    if not IsServer() then return end

    self:SetStackCount(9)

    self:StartIntervalThink(30)
end

function modifier_pvp_damage_layers:OnIntervalThink()
    if self:GetStackCount() < 9 then
        self:IncrementStackCount()
    end
end

function modifier_pvp_damage_layers:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE
    }
end

function modifier_pvp_damage_layers:GetModifierMagicalResistanceBonus()
    return 70
end

function modifier_pvp_damage_layers:GetModifierStatusResistance()
    return 50
end

function modifier_pvp_damage_layers:GetModifierIncomingDamage_Percentage(event)
    if event.attacker:IsRealHero() or event.attacker:IsTempestDouble() or event.attacker:IsIllusion() then
        if self:GetStackCount() > 0 then
            self:DecrementStackCount()
        end

        return -10 * self:GetStackCount()
    end
end

function modifier_pvp_damage_layers:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end