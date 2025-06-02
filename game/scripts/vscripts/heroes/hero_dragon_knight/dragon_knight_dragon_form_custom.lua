LinkLuaModifier("modifier_dragon_knight_dragon_form_custom", "heroes/hero_dragon_knight/dragon_knight_dragon_form_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_green", "heroes/hero_dragon_knight/dragon_form/dragon_form_green", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_red", "heroes/hero_dragon_knight/dragon_form/dragon_form_red", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_blue", "heroes/hero_dragon_knight/dragon_form/dragon_form_blue", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_form_custom_black", "heroes/hero_dragon_knight/dragon_form/dragon_form_black", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

dragon_knight_dragon_form_custom = class(ItemBaseClass)
modifier_dragon_knight_dragon_form_custom = class(dragon_knight_dragon_form_custom)
-------------
function dragon_knight_dragon_form_custom:GetIntrinsicModifierName()
    return "modifier_dragon_knight_dragon_form_custom"
end

function modifier_dragon_knight_dragon_form_custom:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    self.dragonType = nil

    self:OnIntervalThink()
    self:StartIntervalThink(0.1)
end

function modifier_dragon_knight_dragon_form_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_dragon_knight_dragon_form_custom:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    self.dragonType = nil
end

function modifier_dragon_knight_dragon_form_custom:OnIntervalThink()
    if not self:GetParent():IsAlive() then return end

    local mods = {
        "modifier_dragon_knight_dragon_form_switch_custom_green",
        "modifier_dragon_knight_dragon_form_switch_custom_red",
        "modifier_dragon_knight_dragon_form_switch_custom_blue",
        "modifier_dragon_knight_dragon_form_switch_custom_black"
    }

    local modsDrake = {
        "modifier_dragon_knight_dragon_form_custom_green",
        "modifier_dragon_knight_dragon_form_custom_red",
        "modifier_dragon_knight_dragon_form_custom_blue",
        "modifier_dragon_knight_dragon_form_custom_black"
    }

    for i = 1, #mods, 1 do
        if self.parent:HasModifier(mods[i]) and self.dragonType ~= mods[i] then
            self.parent:RemoveModifierByName("modifier_dragon_knight_dragon_form_custom_green")
            self.parent:RemoveModifierByName("modifier_dragon_knight_dragon_form_custom_red")
            self.parent:RemoveModifierByName("modifier_dragon_knight_dragon_form_custom_blue")
            self.parent:RemoveModifierByName("modifier_dragon_knight_dragon_form_custom_black")

            self.parent:AddNewModifier(self.parent, self.ability, modsDrake[i], {})
            self.dragonType = mods[i]
            break
        end
    end
end