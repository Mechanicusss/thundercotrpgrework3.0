LinkLuaModifier("modifier_item_conduit_stone", "items/item_conduit_stone/item_conduit_stone", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_conduit_stone = class(ItemBaseClass)
modifier_item_conduit_stone = class(item_conduit_stone)
-------------
function item_conduit_stone:GetIntrinsicModifierName()
    return "modifier_item_conduit_stone"
end
-------------
function modifier_item_conduit_stone:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
end

function modifier_item_conduit_stone:OnCreated()
    if not IsServer() then return end 

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self:StartIntervalThink(interval)
end

function modifier_item_conduit_stone:OnIntervalThink()
    local maxStacks = self:GetAbility():GetSpecialValueFor("max_stacks")
    if self:GetStackCount() < maxStacks then
        self:IncrementStackCount()
    end
end

function modifier_item_conduit_stone:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
    if event.inflictor == nil then return end
    if event.damage <= 0 then return end

    if string.match(event.inflictor:GetAbilityName(), "item_") then return end

    local target = event.unit 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if self:GetStackCount() < 1 then return end

    local bonus = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("damage_per_stack")
    local damage = event.damage * (bonus/100)

    self:SetStackCount(0)

    ApplyDamage({
        attacker = parent,
        victim = target,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        ability = self:GetAbility()
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil)
end