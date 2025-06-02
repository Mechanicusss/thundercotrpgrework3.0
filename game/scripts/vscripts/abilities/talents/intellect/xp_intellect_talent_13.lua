LinkLuaModifier("modifier_xp_intellect_talent_13", "abilities/talents/intellect/xp_intellect_talent_13", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_13 = class(ItemBaseClass)
modifier_xp_intellect_talent_13 = class(xp_intellect_talent_13)
-------------
function xp_intellect_talent_13:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_13"
end
-------------
function modifier_xp_intellect_talent_13:OnCreated()
end

function modifier_xp_intellect_talent_13:OnDestroy()
end

function modifier_xp_intellect_talent_13:DeclareFunctions()
    return {
         MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_xp_intellect_talent_13:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    if not event.inflictor then return end 

    if event.damage_type ~= DAMAGE_TYPE_MAGICAL then return end

    local victim = event.unit 

    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end 

    if not RollPercentage(10) then return end
    
    ApplyDamage({
        attacker = parent,
        victim = victim,
        damage = event.damage * (200/100),
        damage_type = DAMAGE_TYPE_PURE,
    })
end