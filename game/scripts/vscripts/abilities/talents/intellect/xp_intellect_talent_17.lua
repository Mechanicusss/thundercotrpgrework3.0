LinkLuaModifier("modifier_xp_intellect_talent_17", "abilities/talents/intellect/xp_intellect_talent_17", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_17 = class(ItemBaseClass)
modifier_xp_intellect_talent_17 = class(xp_intellect_talent_17)
-------------
function xp_intellect_talent_17:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_17"
end
-------------
function modifier_xp_intellect_talent_17:OnCreated()
end

function modifier_xp_intellect_talent_17:OnDestroy()
end

function modifier_xp_intellect_talent_17:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST     
    }
end

function modifier_xp_intellect_talent_17:OnAbilityFullyCast(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    local noTarget = false

    if event.target == nil then noTarget = true end

    local parent = self:GetParent()
    local inflictor = event.ability

    if inflictor:IsItem() then return end

    if inflictor:GetAbilityName() == "void_spirit_aether_remnant_custom" or inflictor:GetAbilityName() == "timbersaw_chakram_custom" or inflictor:GetAbilityName() == "timbersaw_chakram_2_custom" or inflictor:GetAbilityName() == "hoodwink_sharpshooter_custom" or inflictor:GetAbilityName() == "hoodwink_sharpshooter_cancel_custom" or inflictor:GetAbilityName() == "zuus_transcendence_custom" or inflictor:GetAbilityName() == "zuus_transcendence_custom_descend" or inflictor:GetAbilityName() == "necrolyte_reaper_form" or inflictor:GetAbilityName() == "necrolyte_reaper_form_exit" or inflictor:GetAbilityName() == "lich_ice_spire_custom" then return end
    
    if bit.band(inflictor:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_CHANNELLED) ~= 0 then return end
    
    if not RollPercentage(25) then
        self.count = 0
        return
    end

    self.count = self.count + 1

    local castPos = parent:GetCursorPosition()

    if not noTarget then
        Timers:CreateTimer(0.2, function()
            SpellCaster:Cast(inflictor, event.target, false)
        end)
    else
        Timers:CreateTimer(0.2, function()
            SpellCaster:Cast(inflictor, castPos, false)
        end)
    end
end