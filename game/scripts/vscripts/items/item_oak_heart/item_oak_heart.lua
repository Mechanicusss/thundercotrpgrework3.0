LinkLuaModifier("modifier_item_oak_heart", "items/item_oak_heart/item_oak_heart", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

item_oak_heart = class(ItemBaseClass)
modifier_item_oak_heart = class(item_oak_heart)
-------------
function item_oak_heart:GetIntrinsicModifierName()
    return "modifier_item_oak_heart"
end

function modifier_item_oak_heart:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    }
end

function modifier_item_oak_heart:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetAbility():GetSpecialValueFor("outgoing_damage_pct")
end

function modifier_item_oak_heart:CheckState()
    if self:GetParent():IsAlive() then
        return {
            [MODIFIER_STATE_DISARMED] = true,
            [MODIFIER_STATE_MUTED] = true,
            [MODIFIER_STATE_SILENCED] = true
        }
    end
end

function modifier_item_oak_heart:GetPriority() return 4 end

function modifier_item_oak_heart:GetEffectName() return "particles/units/heroes/hero_demonartist/demonartist_engulf_disarm/items2_fx/heavens_halberd.vpcf" end
function modifier_item_oak_heart:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end