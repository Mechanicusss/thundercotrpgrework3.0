LinkLuaModifier("modifier_apocalypse_life_blood", "modifiers/apocalypse_modifiers/life_blood", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_apocalypse_life_blood = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
})

modifier_apocalypse_life_blood = class(ItemBaseClass)

function modifier_apocalypse_life_blood:GetIntrinsicModifierName()
    return "modifier_apocalypse_life_blood"
end

function modifier_apocalypse_life_blood:GetTexture() return "arena/kadash_survival_skills" end
-------------
function modifier_apocalypse_life_blood:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,  
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_apocalypse_life_blood:OnTakeDamage(event)
    if event.unit ~= self:GetParent() then return end

    self:OnRefresh()
end

function modifier_apocalypse_life_blood:OnCreated()
    self.aps = 0

    self:OnRefresh()
end

function modifier_apocalypse_life_blood:OnRefresh()
    local currentPct = self:GetParent():GetHealthPercent()
    local bonus = 25 * ((100 - currentPct) / 10)

    self.aps = bonus
end

function modifier_apocalypse_life_blood:GetModifierAttackSpeedBonus_Constant()
    return self.aps
end