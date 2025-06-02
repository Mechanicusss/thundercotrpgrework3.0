LinkLuaModifier("modifier_xp_intellect_talent_7", "abilities/talents/intellect/xp_intellect_talent_7", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

xp_intellect_talent_7 = class(ItemBaseClass)
modifier_xp_intellect_talent_7 = class(xp_intellect_talent_7)
-------------
function xp_intellect_talent_7:GetIntrinsicModifierName()
    return "modifier_xp_intellect_talent_7"
end
-------------
function modifier_xp_intellect_talent_7:OnCreated()
end

function modifier_xp_intellect_talent_7:OnDestroy()
end

function modifier_xp_intellect_talent_7:DeclareFunctions()
    return {
         MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_xp_intellect_talent_7:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    if not event.inflictor then return end 

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then return end

    local victim = event.unit 

    if not IsBossTCOTRPG(victim) and not IsCreepTCOTRPG(victim) then return end 
    
    ApplyDamage({
        attacker = parent,
        victim = victim,
        damage = parent:GetBaseIntellect() * (10/100),
        damage_type = event.damage_type,
    })
end