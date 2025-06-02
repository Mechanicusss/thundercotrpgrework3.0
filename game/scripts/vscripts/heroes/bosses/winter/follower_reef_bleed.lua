LinkLuaModifier("modifier_follower_reef_bleed", "heroes/bosses/winter/follower_reef_bleed", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_follower_reef_bleed_debuff", "heroes/bosses/winter/follower_reef_bleed", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

follower_reef_bleed = class(ItemBaseClass)
modifier_follower_reef_bleed = class(follower_reef_bleed)
modifier_follower_reef_bleed_debuff = class(ItemBaseClassDebuff)
-------------
function follower_reef_bleed:GetIntrinsicModifierName()
    return "modifier_follower_reef_bleed"
end

function modifier_follower_reef_bleed:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_follower_reef_bleed:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    event.target:AddNewModifier(parent, self:GetAbility(), "modifier_follower_reef_bleed_debuff", {
        duration = self:GetAbility():GetSpecialValueFor("duration")
    })
end
-------
function modifier_follower_reef_bleed_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_follower_reef_bleed_debuff:OnIntervalThink()
    ApplyDamage({
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        ability = self:GetAbility(),
        damage = self:GetParent():GetHealth() * (self:GetAbility():GetSpecialValueFor("current_hp_damage")/100),
        damage_type = DAMAGE_TYPE_MAGICAL,
    })
end

function modifier_follower_reef_bleed_debuff:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end