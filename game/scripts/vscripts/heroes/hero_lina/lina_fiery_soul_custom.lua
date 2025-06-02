LinkLuaModifier("modifier_lina_fiery_soul_custom", "heroes/hero_lina/lina_fiery_soul_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_fiery_soul_custom_def", "heroes/hero_lina/lina_fiery_soul_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lina_fiery_soul_custom_buff", "heroes/hero_lina/lina_fiery_soul_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
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

lina_fiery_soul_custom = class(ItemBaseClass)
modifier_lina_fiery_soul_custom = class(ItemBaseClassBuff)
modifier_lina_fiery_soul_custom_buff = class(ItemBaseClassBuff)
modifier_lina_fiery_soul_custom_def = class(ItemBaseClass)
-------------
function lina_fiery_soul_custom:GetIntrinsicModifierName()
  return "modifier_lina_fiery_soul_custom_def"
end
--------------
function modifier_lina_fiery_soul_custom_def:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local sunray = caster:FindAbilityByName("lina_sun_ray_custom")
    if sunray then
        sunray:SetActivated(false)
    end
end

function modifier_lina_fiery_soul_custom_def:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    }
end

function modifier_lina_fiery_soul_custom_def:OnAbilityExecuted(event)
    local caster = self:GetCaster()

    if event.unit ~= caster then return end
    if not event.ability then return end
    if event.ability:GetAbilityName() ~= "lina_dragon_slave_custom" and event.ability:GetAbilityName() ~= "lina_light_strike_array_custom" and event.ability:GetAbilityName() ~= "lina_laguna_blade_custom" then return end
    if caster:HasModifier("modifier_lina_fiery_soul_custom_buff") then return end
    local ability = self:GetAbility()

    if not ability:IsActivated() then return end

    local mod = caster:FindModifierByName("modifier_lina_fiery_soul_custom")
    if not mod then
        mod = caster:AddNewModifier(caster, ability, "modifier_lina_fiery_soul_custom", {
            duration = ability:GetSpecialValueFor("fiery_soul_stack_duration")
        })
    end

    if mod then
        if mod:GetStackCount() < ability:GetSpecialValueFor("fiery_soul_max_stacks") then
            mod:IncrementStackCount()
        end

        if mod:GetStackCount() == ability:GetSpecialValueFor("fiery_soul_max_stacks") then
            caster:AddNewModifier(caster, ability, "modifier_lina_fiery_soul_custom_buff", {
                duration = ability:GetSpecialValueFor("overheat_duration")
            })
        end

        mod:ForceRefresh()
    end
end
--------------
function modifier_lina_fiery_soul_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ABILITY_EXECUTED,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_lina_fiery_soul_custom:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("fiery_soul_attack_speed_bonus") * self:GetStackCount()
end

function modifier_lina_fiery_soul_custom:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("fiery_soul_move_speed_bonus") * self:GetStackCount()
end
----------------
function modifier_lina_fiery_soul_custom_buff:CheckState()
    return {
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    }
end

function modifier_lina_fiery_soul_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("Hero_Lina.FlameCloak.Cast", parent)

    self.effect = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_flame_cloak_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(
        self.effect,
        1,
        parent,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    local sunray = parent:FindAbilityByName("lina_sun_ray_custom")
    if not sunray then return end

    local fiery = parent:FindModifierByName("modifier_lina_fiery_soul_custom")
    if fiery then
        fiery:Destroy()
    end

    fiery = parent:AddNewModifier(parent, self:GetAbility(), "modifier_lina_fiery_soul_custom", {})

    if fiery then
        fiery:SetStackCount(self:GetAbility():GetSpecialValueFor("fiery_soul_max_stacks"))
    end

    sunray:SetLevel(self:GetAbility():GetLevel())
    sunray:SetActivated(true)
end

function modifier_lina_fiery_soul_custom_buff:OnDestroy()
    if not IsServer() then return end

    if self.effect ~= nil then
        ParticleManager:DestroyParticle(self.effect, true)
        ParticleManager:ReleaseParticleIndex(self.effect)
    end

    local parent = self:GetParent()
    parent:RemoveModifierByName("modifier_lina_fiery_soul_custom")

    local sunray = parent:FindAbilityByName("lina_sun_ray_custom")
    if not sunray then return end

    sunray:SetActivated(false)
end