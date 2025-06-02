LinkLuaModifier("modifier_enchantress_impetus_custom", "creeps/impetus", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    Isdebuff = function(self) return true end,
}

enchantress_impetus_custom = class(ItemBaseClass)
modifier_enchantress_impetus_custom = class(enchantress_impetus_custom)
-------------
function enchantress_impetus_custom:GetIntrinsicModifierName()
    return "modifier_enchantress_impetus_custom"
end


function modifier_enchantress_impetus_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_enchantress_impetus_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_enchantress_impetus_custom:OnAttackLanded(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()

    local damage = parent:GetAverageTrueAttackDamage(parent) * (ability:GetSpecialValueFor("damage_pct")/100)
    
    ApplyDamage({
        victim = victim,
        attacker = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, victim, damage, nil)
end

function modifier_enchantress_impetus_custom:GetModifierProjectileName()
    return "particles/econ/items/enchantress/enchantress_virgas/ench_impetus_virgas.vpcf"
end