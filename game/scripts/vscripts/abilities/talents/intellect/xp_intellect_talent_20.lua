LinkLuaModifier("modifier_xp_intellect_talent_20", "abilities/talents/intellect/xp_intellect_talent_20", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xp_intellect_talent_20_debuff", "abilities/talents/intellect/xp_intellect_talent_20", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_20 = class(ItemBaseClass)
modifier_xp_intellect_talent_20 = class(xp_intellect_talent_20)
modifier_xp_intellect_talent_20_debuff = class(ItemBaseClassDebuff)
-------------
function xp_intellect_talent_20:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_20"
end
-------------
function modifier_xp_intellect_talent_20:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_xp_intellect_talent_20:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    if not event.inflictor then return end 

    if string.match(event.inflictor:GetAbilityName(), "xp_intellect_talent") then return end 

    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local victim = event.unit 

    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end 
    
    victim:AddNewModifier(parent, nil, "modifier_xp_intellect_talent_20_debuff", {
        duration = 3
    })
end

function modifier_xp_intellect_talent_20:OnDestroy()
end
-------------
function modifier_xp_intellect_talent_20_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE      
    }
end

function modifier_xp_intellect_talent_20_debuff:GetModifierMagicalResistanceDecrepifyUnique( params )
    return 0.5 * self:GetStackCount() * (-1)
end