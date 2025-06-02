LinkLuaModifier("modifier_player_buffs_critical_strike", "modifiers/player_buffs/modifier_player_buffs_critical_strike", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_critical_strike = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_critical_strike = class(ItemBaseClass)

function modifier_player_buffs_critical_strike:GetIntrinsicModifierName()
    return "modifier_player_buffs_critical_strike"
end

function modifier_player_buffs_critical_strike:GetTexture() return "player_buffs/modifier_player_buffs_critical_strike" end
-------------
function modifier_player_buffs_critical_strike:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,  
    }

    return funcs
end

function modifier_player_buffs_critical_strike:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY) ~= 0 then return end

    if not RollPercentage(24) then return end 

    local damage = event.damage * 2

    ApplyDamage({
        attacker = parent,
        victim = event.unit,
        damage = damage,
        damage_type = event.damage_type,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
    })

    local overheadType = OVERHEAD_ALERT_BONUS_SPELL_DAMAGE

    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        overheadType = OVERHEAD_ALERT_CRITICAL 
    end

    SendOverheadEventMessage(nil, overheadType, event.unit, damage, nil)
end