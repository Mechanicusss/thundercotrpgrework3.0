LinkLuaModifier("modifier_player_difficulty_boon_disarm_30", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_disarm_30", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_disarm_30_disarmed", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_disarm_30", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_disarm_30_countdown", "modifiers/modes/buffs/impossible/modifier_player_difficulty_boon_disarm_30", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_disarm_30 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_disarm_30_disarmed = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})

modifier_player_difficulty_boon_disarm_30_countdown = class({
    IsPurgable = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsDebuff = function(self) return true end,
})


modifier_player_difficulty_boon_disarm_30 = class(ItemBaseClass)

function player_difficulty_boon_disarm_30:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_disarm_30"
end

function modifier_player_difficulty_boon_disarm_30:GetTexture() return "disarm" end
function modifier_player_difficulty_boon_disarm_30_disarmed:GetTexture() return "disarm" end
function modifier_player_difficulty_boon_disarm_30_countdown:GetTexture() return "disarm" end

function modifier_player_difficulty_boon_disarm_30:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK,
    }

    return funcs
end

function modifier_player_difficulty_boon_disarm_30:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1.0)
end

function modifier_player_difficulty_boon_disarm_30:OnIntervalThink()
    local parent = self:GetParent()
    
    if not parent:HasModifier("modifier_player_difficulty_boon_disarm_30_countdown") then
        parent:AddNewModifier(parent, nil, "modifier_player_difficulty_boon_disarm_30_countdown", {
            duration = 10
        })
    end
end
--------------
function modifier_player_difficulty_boon_disarm_30_countdown:OnRemoved(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    if not parent:IsAlive() then return end

    parent:AddNewModifier(parent, nil, "modifier_player_difficulty_boon_disarm_30_disarmed", {
        duration = 2
    })

    EmitSoundOn("Hero_Pangolier.LuckyShot.Proc", parent)

    parent:AddNewModifier(parent, nil, "modifier_player_difficulty_boon_disarm_30_countdown", {
        duration = 12
    })
end
-------------
function modifier_player_difficulty_boon_disarm_30_disarmed:CheckState()
    local state = {
        [MODIFIER_STATE_DISARMED] = true
    }
    return state
end

function modifier_player_difficulty_boon_disarm_30_disarmed:GetStatusEffectName()
    return "particles/generic_gameplay/generic_disarm.vpcf"
end