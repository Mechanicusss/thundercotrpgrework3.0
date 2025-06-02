LinkLuaModifier("modifier_enemy_difficulty_buff_wraith_5_10", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_wraith_5_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_wraith_5_10_buff", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_wraith_5_10", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_wraith_5_10_buff_disabled", "modifiers/modes/buffs/impossible/modifier_enemy_difficulty_buff_wraith_5_10", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_wraith_5_10 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_wraith_5_10_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_wraith_5_10 = class(ItemBaseClass)
modifier_enemy_difficulty_buff_wraith_5_10_buff_disabled = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

function enemy_difficulty_buff_wraith_5_10:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_wraith_5_10"
end

function modifier_enemy_difficulty_buff_wraith_5_10:GetTexture() return "wraith" end
function modifier_enemy_difficulty_buff_wraith_5_10_buff:GetTexture() return "wraith" end
-------------
function modifier_enemy_difficulty_buff_wraith_5_10_buff:OnCreated()
    if not IsServer() then return end

    self.oldScale = self:GetParent():GetModelScale()
    self.oldColor = self:GetParent():GetRenderColor()

    self:GetParent():SetModelScale(self:GetParent():GetModelScale() * 1.3)
    self:GetParent():SetRenderColor(0, 255, 0)

    self:StartIntervalThink(0.1)

    self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_enemy_difficulty_buff_wraith_5_10_buff_disabled", {})
end

function modifier_enemy_difficulty_buff_wraith_5_10_buff:OnRemoved()
    if not IsServer() then return end

    self:GetParent():SetModelScale(self.oldScale)
    self:GetParent():SetRenderColor(0, 0, 0)
end

function modifier_enemy_difficulty_buff_wraith_5_10_buff:GetEffectName()
    return "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf"
end

function modifier_enemy_difficulty_buff_wraith_5_10_buff:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetHealthPercent() >= 99 then
        parent:RemoveModifierByName("modifier_enemy_difficulty_buff_wraith_5_10_buff")
        self:StartIntervalThink(-1)
        return
    end

    parent:Heal(((parent:GetMaxHealth() * 0.025) * 0.1), self:GetAbility())
    
end