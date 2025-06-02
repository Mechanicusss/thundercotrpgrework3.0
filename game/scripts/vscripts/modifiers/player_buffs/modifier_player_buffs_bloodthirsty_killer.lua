-- WARNING: THE ANTI-HEAL IS DONE IN THE HEALING FILTER
LinkLuaModifier("modifier_player_buffs_bloodthirsty_killer", "modifiers/player_buffs/modifier_player_buffs_bloodthirsty_killer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_bloodthirsty_killer_buff", "modifiers/player_buffs/modifier_player_buffs_bloodthirsty_killer", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_bloodthirsty_killer_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_bloodthirsty_killer = class(ItemBaseClass)

function modifier_player_buffs_bloodthirsty_killer:GetIntrinsicModifierName()
    return "modifier_player_buffs_bloodthirsty_killer"
end

function modifier_player_buffs_bloodthirsty_killer:GetTexture() return "player_buffs/modifier_player_buffs_bloodthirsty_killer" end
-------------
function modifier_player_buffs_bloodthirsty_killer:OnCreated()
    if not IsServer() then return end 

    self.kills = 0
end

function modifier_player_buffs_bloodthirsty_killer:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_player_buffs_bloodthirsty_killer:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end

    local unit = event.unit 

    if not IsCreepTCOTRPG(unit) and not IsBossTCOTRPG(unit) then return end 

    self.kills = self.kills + 1

    if self.kills == 1000 then
        parent:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_bloodthirsty_killer_buff", {})
    end
end
--------------------
function modifier_player_buffs_bloodthirsty_killer_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS, 
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, 
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, 
    }
end

function modifier_player_buffs_bloodthirsty_killer_buff:GetModifierBonusStats_Strength()
    return 1000
end

function modifier_player_buffs_bloodthirsty_killer_buff:GetModifierBonusStats_Intellect()
    return 1000
end

function modifier_player_buffs_bloodthirsty_killer_buff:GetModifierBonusStats_Agility()
    return 1000
end