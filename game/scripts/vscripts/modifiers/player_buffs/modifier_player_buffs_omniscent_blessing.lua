LinkLuaModifier("modifier_player_buffs_omniscent_blessing", "modifiers/player_buffs/modifier_player_buffs_omniscent_blessing", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_buffs_omniscent_blessing_damage", "modifiers/player_buffs/modifier_player_buffs_omniscent_blessing", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

modifier_player_buffs_omniscent_blessing = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
})

modifier_player_buffs_omniscent_blessing_damage = class({
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_player_buffs_omniscent_blessing = class(ItemBaseClass)

function modifier_player_buffs_omniscent_blessing:GetIntrinsicModifierName()
    return "modifier_player_buffs_omniscent_blessing"
end

function modifier_player_buffs_omniscent_blessing:GetTexture() return "player_buffs/modifier_player_buffs_omniscent_blessing" end
-------------
function modifier_player_buffs_omniscent_blessing:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,  
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_player_buffs_omniscent_blessing:GetModifierHealAmplify_PercentageSource()
    return 100
end

function modifier_player_buffs_omniscent_blessing:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker or parent == event.unit then return end 

    if parent:HasModifier("modifier_player_buffs_omniscent_blessing_damage") then return end

    local debuff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_player_buffs_omniscent_blessing_damage", {
        damage = event.damage,
        duration = 3
    })
end
------------------
function modifier_player_buffs_omniscent_blessing_damage:OnCreated(params)
    if not IsServer() then return end 

    self.damage = params.damage/params.duration

    self:StartIntervalThink(1)
end

function modifier_player_buffs_omniscent_blessing_damage:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = self.damage,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL,
    })
end