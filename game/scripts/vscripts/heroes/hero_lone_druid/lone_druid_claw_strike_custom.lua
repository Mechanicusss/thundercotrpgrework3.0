LinkLuaModifier("modifier_lone_druid_claw_strike_custom", "heroes/hero_lone_druid/lone_druid_claw_strike_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

lone_druid_claw_strike_custom = class(ItemBaseClass)
modifier_lone_druid_claw_strike_custom = class(lone_druid_claw_strike_custom)
-------------
function lone_druid_claw_strike_custom:GetIntrinsicModifierName()
    return "modifier_lone_druid_claw_strike_custom"
end
------------
function modifier_lone_druid_claw_strike_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_lone_druid_claw_strike_custom:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local talent = parent:FindAbilityByName("talent_lone_druid_1")
    if not talent or (talent ~= nil and talent:GetLevel() < 2) then
        return
    end

    local ability = self:GetAbility()

    if not ability then return end 

    if ability:GetLevel() < 1 then return end

    if not ability:IsActivated() then return end

    if not ability:IsCooldownReady() then return end 

    target:AddNewModifier(parent, nil, "modifier_stunned", {
        duration = ability:GetSpecialValueFor("stun_duration")
    })

    EmitSoundOn("DOTA_Item.SkullBasher", target)

    ability:UseResources(false, false, false, true)
end