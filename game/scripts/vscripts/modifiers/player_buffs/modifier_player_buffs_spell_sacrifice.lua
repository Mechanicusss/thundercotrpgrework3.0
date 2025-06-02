LinkLuaModifier("modifier_player_buffs_spell_sacrifice", "modifiers/player_buffs/modifier_player_buffs_spell_sacrifice", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_spell_sacrifice = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_spell_sacrifice = class(ItemBaseClass)

function modifier_player_buffs_spell_sacrifice:GetIntrinsicModifierName()
    return "modifier_player_buffs_spell_sacrifice"
end

function modifier_player_buffs_spell_sacrifice:GetTexture() return "player_buffs/modifier_player_buffs_spell_sacrifice" end
-------------
function modifier_player_buffs_spell_sacrifice:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED, 
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, 
    }

    return funcs
end

function modifier_player_buffs_spell_sacrifice:GetModifierTotalDamageOutgoing_Percentage(event)
    if not event.inflictor then return end 
    if event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end

    return 50
end

function modifier_player_buffs_spell_sacrifice:OnAbilityExecuted(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.unit then return end 

    if string.match(event.ability:GetAbilityName(), "item_") then return end

    local damage = parent:GetHealth() * 0.025

    ApplyDamage({
        attacker = parent,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL,
    })
end