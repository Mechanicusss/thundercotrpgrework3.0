LinkLuaModifier("modifier_enemy_difficulty_buff_wraith_5_20", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_wraith_5_20", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_enemy_difficulty_buff_wraith_5_20_buff", "modifiers/modes/buffs/unfair/modifier_enemy_difficulty_buff_wraith_5_20", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

enemy_difficulty_buff_wraith_5_20 = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
})

modifier_enemy_difficulty_buff_wraith_5_20_buff = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
})

modifier_enemy_difficulty_buff_wraith_5_20 = class(ItemBaseClass)

function enemy_difficulty_buff_wraith_5_20:GetIntrinsicModifierName()
    return "modifier_enemy_difficulty_buff_wraith_5_20"
end

function modifier_enemy_difficulty_buff_wraith_5_20:GetTexture() return "wraith" end
function modifier_enemy_difficulty_buff_wraith_5_20_buff:GetTexture() return "wraith" end
-------------
function modifier_enemy_difficulty_buff_wraith_5_20_buff:OnCreated()
    if not IsServer() then return end

    self.oldScale = self:GetParent():GetModelScale()
    self.oldColor = self:GetParent():GetRenderColor()

    self:GetParent():SetModelScale(self:GetParent():GetModelScale() * 1.3)
    self:GetParent():SetRenderColor(0, 255, 0)

    self:StartIntervalThink(0.1)
end

function modifier_enemy_difficulty_buff_wraith_5_20_buff:OnRemoved()
    if not IsServer() then return end

    self:GetParent():SetModelScale(self.oldScale)
    self:GetParent():SetRenderColor(self.oldColor)
end

function modifier_enemy_difficulty_buff_wraith_5_20_buff:GetEffectName()
    return "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf"
end

function modifier_enemy_difficulty_buff_wraith_5_20_buff:OnIntervalThink()
    local parent = self:GetParent()

    if parent:GetHealthPercent() >= 99 then
        parent:RemoveModifierByName("modifier_enemy_difficulty_buff_wraith_5_20_buff")
        self:StartIntervalThink(-1)
        return
    end

    parent:Heal((((parent:GetMaxHealth()) * 0.05) * 0.1), self:GetAbility())
    
end