LinkLuaModifier("modifier_item_lance_pursuit", "items/item_lance_pursuit/item_lance_pursuit", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

item_lance_pursuit = class(ItemBaseClass)
modifier_item_lance_pursuit = class(item_lance_pursuit)
-------------
function item_lance_pursuit:GetIntrinsicModifierName()
    return "modifier_item_lance_pursuit"
end
-------------
function modifier_item_lance_pursuit:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_item_lance_pursuit:GetModifierAttackRangeBonus()
    if not self:GetParent():IsRangedAttacker() then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    end
end

function modifier_item_lance_pursuit:OnAttackLanded(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    -- Find targets back
    -- Thanks to DOTA IMBA for the code (https://github.com/EarthSalamander42/dota_imba/blob/master/game/scripts/vscripts/components/abilities/heroes/hero_riki#L1193)
    local target_angle = target:GetAnglesAsVector().y
    local origin_difference = target:GetAbsOrigin() - parent:GetAbsOrigin()
    local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)
    origin_difference_radian = origin_difference_radian * 180

    local attacker_angle = origin_difference_radian / math.pi

    -- For some reason Dota mechanics read the result as 30 degrees anticlockwise, need to adjust it down to appropriate angles for backstabbing.
    attacker_angle = attacker_angle + 180.0 + 30.0

    local result_angle = attacker_angle - target_angle
    result_angle = math.abs(result_angle)

    local backstabAngle = 105 -- Same as riki's backstab angle

    if result_angle >= (180 - (backstabAngle / 2)) and result_angle <= (180 + (backstabAngle / 2)) then
        local ability = self:GetAbility()
        local damage = event.damage * (ability:GetSpecialValueFor("damage_to_pure")/100)

        ApplyDamage({
            attacker = parent,
            target = target,
            damage = damage,
            damage_type = DAMAGE_TYPE_PURE,
            ability = ability
        })

        SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil)
    end
end