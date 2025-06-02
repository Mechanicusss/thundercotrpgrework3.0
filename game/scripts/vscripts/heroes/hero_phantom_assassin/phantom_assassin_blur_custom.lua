LinkLuaModifier("modifier_phantom_assassin_blur_custom", "heroes/hero_phantom_assassin/phantom_assassin_blur_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phantom_assassin_blur_custom_buff", "heroes/hero_phantom_assassin/phantom_assassin_blur_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseDoubleAttackClass = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

phantom_assassin_blur_custom = class(ItemBaseClass)
modifier_phantom_assassin_blur_custom = class(phantom_assassin_blur_custom)
modifier_phantom_assassin_blur_custom_buff = class(ItemBaseDoubleAttackClass)
-------------
function modifier_phantom_assassin_blur_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur.vpcf"
end

function modifier_phantom_assassin_blur_custom_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS   
    }

    return funcs
end

function modifier_phantom_assassin_blur_custom_buff:GetModifierBonusStats_Agility()
    if not IsServer() then return end 
    
    if self.lockAgility then return 0 end

    self.lockAgility = true

    local agility = self:GetParent():GetBaseAgility()

    self.lockAgility = false

    local bonus = agility * (self:GetAbility():GetSpecialValueFor("bonus_agility_per_proc_pct")/100) * self:GetStackCount()
    
    return bonus
end
-------------
function phantom_assassin_blur_custom:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_blur_custom"
end

function phantom_assassin_blur_custom:GetEffectName()
    return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_active_blur_light.vpcf"
end

function modifier_phantom_assassin_blur_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_EVENT_ON_ATTACK_FAIL 
    }

    return funcs
end

function modifier_phantom_assassin_blur_custom:GetModifierEvasion_Constant()
    return self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_phantom_assassin_blur_custom:OnAttackFail(event)
    if not IsServer() then return end 
    
    local parent = self:GetParent()

    if parent ~= event.target then return end 

    if event.fail_type ~= DOTA_ATTACK_RECORD_FAIL_TARGET_EVADED then return end

    local buff = parent:FindModifierByName("modifier_phantom_assassin_blur_custom_buff")

    if not buff then
        buff = parent:AddNewModifier(parent, self:GetAbility(), "modifier_phantom_assassin_blur_custom_buff", {
            duration = self:GetAbility():GetSpecialValueFor("bonus_agility_duration")
        })
    end

    if buff then
        if buff:GetStackCount() < self:GetAbility():GetSpecialValueFor("bonus_agility_max_stacks") then
            buff:IncrementStackCount()
        end

        buff:ForceRefresh()
    end
end
