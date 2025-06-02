LinkLuaModifier("modifier_item_quiver_of_enchants", "items/item_quiver_of_enchants/item_quiver_of_enchants", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_quiver_of_enchants_buff", "items/item_quiver_of_enchants/item_quiver_of_enchants", LUA_MODIFIER_MOTION_NONE)

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
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

item_quiver_of_enchants = class(ItemBaseClass)
modifier_item_quiver_of_enchants = class(item_quiver_of_enchants)
modifier_item_quiver_of_enchants_buff = class(ItemBaseClassBuff)
-------------
function item_quiver_of_enchants:GetIntrinsicModifierName()
    return "modifier_item_quiver_of_enchants"
end

function item_quiver_of_enchants:OnProjectileHit(hTarget, hLoc)
    local caster = self:GetCaster()
    local damage = caster:GetAverageTrueAttackDamage(caster) * (self:GetSpecialValueFor("magic_attack_damage_pct")/100)

    ApplyDamage({
        victim = hTarget,
        attacker = caster,
        damage = damage,
        ability = self,
        damage_type = DAMAGE_TYPE_MAGICAL
    })

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, hTarget, damage, nil)
end
-------------
function modifier_item_quiver_of_enchants:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
    }
end

function modifier_item_quiver_of_enchants:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() then
        return self:GetAbility():GetSpecialValueFor("bonus_attack_range")
    end
end

function modifier_item_quiver_of_enchants:OnCreated()
    if not IsServer() then return end 

    self:StartIntervalThink(FrameTime())
end

function modifier_item_quiver_of_enchants:OnIntervalThink()
    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end 

    local parent = self:GetParent()
    if parent:IsIllusion() then return end

    if not parent:IsRangedAttacker() then 
        if parent:HasModifier("modifier_item_quiver_of_enchants_buff") then
            parent:RemoveModifierByName("modifier_item_quiver_of_enchants_buff")
        end

        return 
    end
    
    if not parent:HasModifier("modifier_item_quiver_of_enchants_buff") then
        parent:AddNewModifier(parent, ability, "modifier_item_quiver_of_enchants_buff", {})

        ability:UseResources(false, false, false, true)
    end
end
------------
function modifier_item_quiver_of_enchants_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_item_quiver_of_enchants_buff:GetModifierAttackRangeBonus()
    if self:GetParent():IsRangedAttacker() then
        return self:GetAbility():GetSpecialValueFor("magic_attack_range")
    end
end

function modifier_item_quiver_of_enchants_buff:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if event.attacker ~= parent then return end 

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    if not parent:IsRangedAttacker() then return end
    if parent:IsIllusion() then return end

    local proj = {
        Target = target,
        iMoveSpeed = parent:GetProjectileSpeed(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bVisibleToEnemies = true,
        EffectName = parent:GetRangedProjectileName(),
        Ability = self:GetAbility(),
        Source = parent,
        bProvidesVision = true,
        iVisionRadius = 300,
        iVisionTeamNumber = parent:GetTeam()
    }

    ProjectileManager:CreateTrackingProjectile(proj)

    self:Destroy()
end