LinkLuaModifier("modifier_player_difficulty_boon_leaky_2_5", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_leaky_2_5", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_leaky_2_5_hp_debuff", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_leaky_2_5", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_leaky_2_5_mana_debuff", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_leaky_2_5", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_leaky_2_5 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_leaky_2_5_hp_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_player_difficulty_boon_leaky_2_5_mana_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_player_difficulty_boon_leaky_2_5 = class(ItemBaseClass)

function player_difficulty_boon_leaky_2_5:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_leaky_2_5"
end

function modifier_player_difficulty_boon_leaky_2_5:GetTexture() return "dualleak" end
function modifier_player_difficulty_boon_leaky_2_5_hp_debuff:GetTexture() return "hpleak" end
function modifier_player_difficulty_boon_leaky_2_5_mana_debuff:GetTexture() return "manaleak" end
-------------
function modifier_player_difficulty_boon_leaky_2_5:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_SPENT_MANA,
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }

    return funcs
end

function modifier_player_difficulty_boon_leaky_2_5:OnSpentMana(event)
    if not IsServer() then return end
    if event.unit ~= self:GetParent() then return end
    if event.ability == self:GetAbility() then return end
    if event.unit:IsMagicImmune() or event.unit:IsInvulnerable() then return end

    if event.unit:HasModifier("modifier_player_difficulty_boon_leaky_2_5_mana_debuff") then
        return
    end

    event.unit:AddNewModifier(event.unit, nil, "modifier_player_difficulty_boon_leaky_2_5_mana_debuff", { duration = 3.0 })
end

function modifier_player_difficulty_boon_leaky_2_5:OnTakeDamage(event)
    if not IsServer() then return end
    if event.unit ~= self:GetParent() then return end
    if event.attacker == self:GetParent() then return end
    if event.unit:IsMagicImmune() or event.unit:IsInvulnerable() then return end

    if event.unit:HasModifier("modifier_player_difficulty_boon_leaky_2_5_hp_debuff") then
        return
    end

    event.unit:AddNewModifier(event.unit, nil, "modifier_player_difficulty_boon_leaky_2_5_hp_debuff", { duration = 3.0 })
end
-----
function modifier_player_difficulty_boon_leaky_2_5_hp_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_player_difficulty_boon_leaky_2_5_hp_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE 
    }

    return funcs
end

function modifier_player_difficulty_boon_leaky_2_5_hp_debuff:GetModifierHealthRegenPercentage()
    return -100
end

function modifier_player_difficulty_boon_leaky_2_5_hp_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetCaster(),
        damage = (self:GetParent():GetHealth() * 0.025) * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    })
end
----
function modifier_player_difficulty_boon_leaky_2_5_mana_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE  
    }

    return funcs
end

function modifier_player_difficulty_boon_leaky_2_5_mana_debuff:GetModifierTotalPercentageManaRegen()
    return -2.5
end