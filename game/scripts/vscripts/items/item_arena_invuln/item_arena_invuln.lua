LinkLuaModifier("modifier_item_arena_invuln", "items/item_arena_invuln/item_arena_invuln", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_arena_invuln_buff", "items/item_arena_invuln/item_arena_invuln", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_arena_invuln = class(ItemBaseClass)
modifier_item_arena_invuln = class(item_arena_invuln)
modifier_item_arena_invuln_buff = class(ItemBaseClassBuff)
-------------
function item_arena_invuln:GetIntrinsicModifierName()
    return "modifier_item_arena_invuln"
end

function item_arena_invuln:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    caster:AddNewModifier(caster, self, "modifier_item_arena_invuln_buff", {
        duration = self:GetSpecialValueFor("duration")
    })

    self:EndCooldown()
    -- We do this so CD is unnaffected by CDR
    self:StartCooldown(self:GetCooldown(self:GetLevel()))

    EmitSoundOn("Hero_FacelessVoid.Chronosphere.ti11", caster)
end
-------------
function modifier_item_arena_invuln:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT 
    }
end

function modifier_item_arena_invuln:GetModifierMoveSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end
-------------
function modifier_item_arena_invuln_buff:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_STUNNED] = true
    }
end

function modifier_item_arena_invuln_buff:GetPriority() return 9999999 end

function modifier_item_arena_invuln_buff:GetStatusEffectName() return "particles/status_fx/status_effect_faceless_chronosphere.vpcf" end