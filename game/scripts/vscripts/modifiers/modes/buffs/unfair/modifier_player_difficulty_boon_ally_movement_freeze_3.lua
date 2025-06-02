LinkLuaModifier("modifier_player_difficulty_boon_ally_movement_freeze_3", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_ally_movement_freeze_3", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_player_difficulty_boon_ally_movement_freeze_3_debuff", "modifiers/modes/buffs/unfair/modifier_player_difficulty_boon_ally_movement_freeze_3", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

player_difficulty_boon_ally_movement_freeze_3 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_player_difficulty_boon_ally_movement_freeze_3_debuff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})


modifier_player_difficulty_boon_ally_movement_freeze_3 = class(ItemBaseClass)

function player_difficulty_boon_ally_movement_freeze_3:GetIntrinsicModifierName()
    return "modifier_player_difficulty_boon_ally_movement_freeze_3"
end

function modifier_player_difficulty_boon_ally_movement_freeze_3:GetTexture() return "frostbite" end
function modifier_player_difficulty_boon_ally_movement_freeze_3_debuff:GetTexture() return "frostbite" end
-------------
function modifier_player_difficulty_boon_ally_movement_freeze_3:OnCreated()
    if not IsServer() then return end

    if _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] == nil then
        _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] = 0
    end

    self:StartIntervalThink(1.0)
end

function modifier_player_difficulty_boon_ally_movement_freeze_3:OnIntervalThink()
    local parent = self:GetParent()

    if not parent:HasModifier("modifier_player_difficulty_boon_ally_movement_freeze_3_debuff") then
        _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] = _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] + 1
    end

    if _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] >= 3 then
        if parent:HasModifier("modifier_player_difficulty_boon_ally_movement_freeze_3_debuff") then return end

        parent:AddNewModifier(parent, nil, "modifier_player_difficulty_boon_ally_movement_freeze_3_debuff", { duration = 3.0 })
        _G.MovementFreezeCounter[self:GetParent():GetPlayerID()] = 0
    end
end
--
function modifier_player_difficulty_boon_ally_movement_freeze_3_debuff:OnCreated()
    if not IsServer() then return end

    EmitSoundOn("hero_Crystal.frostbite", self:GetParent())

    self:StartIntervalThink(0.1)
end

function modifier_player_difficulty_boon_ally_movement_freeze_3_debuff:OnIntervalThink()
    ApplyDamage({
        victim = self:GetParent(),
        attacker = self:GetParent(),
        damage = (self:GetParent():GetMaxHealth() * 0.1) * 0.1,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL
    })
end

function modifier_player_difficulty_boon_ally_movement_freeze_3_debuff:CheckState()
    local state = {
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
    return state
end

function modifier_player_difficulty_boon_ally_movement_freeze_3_debuff:GetEffectName()
    return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end