LinkLuaModifier("modifier_medusa_heavy_arrows", "heroes/hero_medusa/medusa_heavy_arrows", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

medusa_heavy_arrows = class(ItemBaseClass)
modifier_medusa_heavy_arrows = class(medusa_heavy_arrows)
-------------
function medusa_heavy_arrows:GetIntrinsicModifierName()
    return "modifier_medusa_heavy_arrows"
end

function modifier_medusa_heavy_arrows:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE, --GetModifierAttackSpeedPercentage
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }
    return funcs
end

function modifier_medusa_heavy_arrows:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_speed_loss_pct")
end

function modifier_medusa_heavy_arrows:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_loss_pct")
end

function modifier_medusa_heavy_arrows:GetModifierProcAttack_BonusDamage_Physical(params)
    if IsServer() then
        -- get target
        local target = params.target if target==nil then target = params.unit end
        if target:GetTeamNumber()==self:GetParent():GetTeamNumber() then
            return 0
        end

        -- get modifier stack
        local ability = self:GetAbility()
        local damage = ability:GetSpecialValueFor("bonus_damage")
        local agility = self:GetCaster():GetAgility() * (ability:GetSpecialValueFor("bonus_damage_agility")/100)
        local total = damage + agility

        return total
    end
end