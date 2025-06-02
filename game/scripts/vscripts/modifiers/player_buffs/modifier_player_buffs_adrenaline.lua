LinkLuaModifier("modifier_player_buffs_adrenaline", "modifiers/player_buffs/modifier_player_buffs_adrenaline", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_adrenaline_buff", "modifiers/player_buffs/modifier_player_buffs_adrenaline", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_adrenaline_debuff", "modifiers/player_buffs/modifier_player_buffs_adrenaline", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_adrenaline = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_adrenaline_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_adrenaline_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_player_buffs_adrenaline = class(ItemBaseClass)

function modifier_player_buffs_adrenaline:GetIntrinsicModifierName()
    return "modifier_player_buffs_adrenaline"
end

function modifier_player_buffs_adrenaline:GetTexture() return "player_buffs/modifier_player_buffs_adrenaline" end
-------------
function modifier_player_buffs_adrenaline:OnCreated()
    if not IsServer() then return end 

    self.time = 3

    self:StartIntervalThink(self.time)
end

function modifier_player_buffs_adrenaline:OnIntervalThink()
    local parent = self:GetParent()
    if parent:HasModifier("modifier_player_buffs_adrenaline_debuff") then return end

    local buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_adrenaline_buff", {
        duration = self.time
    })
end
---------------
function modifier_player_buffs_adrenaline_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
    }
    return funcs
end

function modifier_player_buffs_adrenaline_buff:GetModifierPercentageCasttime()
    return 50
end

function modifier_player_buffs_adrenaline_buff:GetModifierAttackSpeedBonus_Constant()
    return 500
end

function modifier_player_buffs_adrenaline_buff:OnCreated(params)
    if not IsServer() then return end 

    self.time = params.duration
end

function modifier_player_buffs_adrenaline_buff:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    local buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_adrenaline_debuff", {
        duration = self.time
    })
end
----------
function modifier_player_buffs_adrenaline_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
    }
    return funcs
end

function modifier_player_buffs_adrenaline_debuff:GetModifierPercentageCasttime()
    return -50
end

function modifier_player_buffs_adrenaline_debuff:GetModifierAttackSpeedBonus_Constant()
    return -500
end