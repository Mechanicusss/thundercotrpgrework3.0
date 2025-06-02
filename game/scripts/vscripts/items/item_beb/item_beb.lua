LinkLuaModifier("modifier_item_beb", "items/item_beb/item_beb", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_beb_aura", "items/item_beb/item_beb", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_beb = class(ItemBaseClass)
modifier_item_beb = class(item_beb)
modifier_item_beb_aura = class(ItemBaseClassBuff)
-------------
function item_beb:GetIntrinsicModifierName()
    return "modifier_item_beb"
end

function item_beb:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
--------------
function modifier_item_beb:IsAura()
    return true
end

function modifier_item_beb:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_item_beb:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_beb:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_beb:GetModifierAura()
    return "modifier_item_beb_aura"
end

function modifier_item_beb:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_item_beb:GetAuraEntityReject(target)
    if target:IsIllusion() or not target:IsRealHero() or target == self:GetCaster() then return true end 

    return false
end

function modifier_item_beb:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    
    ability.count = ability.count or 0
    ability.count = 0
end

function modifier_item_beb:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_beb:GetModifierTotalDamageOutgoing_Percentage()
    if self:GetAbility().count ~= nil and self:GetAbility().count > 0 then
        print("bonus damage active!")
        return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    end
end
-----------
function modifier_item_beb_aura:OnCreated()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    
    ability.count = ability.count or 0
    ability.count = ability.count + 1
end

function modifier_item_beb_aura:OnRemoved()
    if not IsServer() then return end 

    local ability = self:GetAbility()
    
    ability.count = ability.count or 0
    ability.count = ability.count - 1
end

function modifier_item_beb_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
end

function modifier_item_beb_aura:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end