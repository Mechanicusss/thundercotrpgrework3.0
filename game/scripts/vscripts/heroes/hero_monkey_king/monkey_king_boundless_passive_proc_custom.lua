LinkLuaModifier("modifier_monkey_king_boundless_passive_proc_custom", "heroes/hero_monkey_king/monkey_king_boundless_passive_proc_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_monkey_king_boundless_passive_proc_custom_buff_permanent", "heroes/hero_monkey_king/monkey_king_boundless_passive_proc_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

monkey_king_boundless_passive_proc_custom = class(ItemBaseClass)
modifier_monkey_king_boundless_passive_proc_custom = class(monkey_king_boundless_passive_proc_custom)
-------------
function monkey_king_boundless_passive_proc_custom:GetIntrinsicModifierName()
    return "modifier_monkey_king_boundless_passive_proc_custom"
end

function modifier_monkey_king_boundless_passive_proc_custom:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_monkey_king_boundless_passive_proc_custom:OnIntervalThink()
    if self:GetParent():HasModifier("modifier_item_aghanims_shard") then
        self:GetParent():RemoveModifierByName("modifier_item_aghanims_shard")
        DisplayError(self:GetParent():GetPlayerID(), "Item Not Allowed On This Hero")
    end
end

function modifier_monkey_king_boundless_passive_proc_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK
    }
    return funcs
end

function modifier_monkey_king_boundless_passive_proc_custom:OnAttack(event)
    if not IsServer() then return end
    
    if event.attacker ~= self:GetParent() then return end

    local ability = self:GetAbility()

    local parent = event.attacker

    if parent:PassivesDisabled() then return end
    if event.attacker:IsIllusion() then return end
    
    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    local boundlessStrike = parent:FindAbilityByName("monkey_king_boundless_strike_custom")
    if boundlessStrike ~= nil and boundlessStrike:GetLevel() > 0 then
        if not boundlessStrike:IsCooldownReady() then return end
        if parent:GetMana() > boundlessStrike:GetManaCost(boundlessStrike:GetLevel()) then
            parent:StartGesture(ACT_DOTA_MK_STRIKE)
            SpellCaster:Cast(boundlessStrike, event.target, true)
            --ability:UseResources(false, false, true)
        end
    end
end