LinkLuaModifier("modifier_dummy_wearable_hero", "modifiers/modifier_dummy_wearable_hero", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    RemoveOnDeath = function(self) return false end,
}

dummy_wearable_hero = class(ItemBaseClass)
modifier_dummy_wearable_hero = class(dummy_wearable_hero)

function modifier_dummy_wearable_hero:GetTexture() return "shield" end
-----------------
function dummy_wearable_hero:GetIntrinsicModifierName()
    return "modifier_dummy_wearable_hero"
end

function modifier_dummy_wearable_hero:OnCreated()
    if not IsServer() then return end

    local player = self:GetCaster()
    local dummy = self:GetParent()
    
    dummy:FollowEntity(player, true)
end

function modifier_dummy_wearable_hero:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_UNTARGETABLE] = true,
        [MODIFIER_STATE_UNSLOWABLE] = true,
        [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_DISARMED] = true

    }
end