LinkLuaModifier("modifier_bristleback_warpath_custom", "heroes/hero_bristleback/warpath", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bristleback_warpath_custom_stacks", "heroes/hero_bristleback/warpath", LUA_MODIFIER_MOTION_NONE)

local ItemBaseStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

bristleback_warpath_custom = class(ItemBaseClass)
modifier_bristleback_warpath_custom = class(bristleback_warpath_custom)
modifier_bristleback_warpath_custom_stacks = class(ItemBaseStacks)

function modifier_bristleback_warpath_custom_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_bristleback_warpath_custom_stacks:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MODEL_SCALE,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE   , --GetModifierPreAttack_BonusDamage
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
    }
    return funcs
end

function modifier_bristleback_warpath_custom_stacks:OnTooltip()
    return ((self:GetAbility():GetSpecialValueFor("damage_per_stack") + self.fDamage) * self:GetStackCount())
end

function modifier_bristleback_warpath_custom_stacks:GetModifierPreAttack_BonusDamage()
    return ((self:GetAbility():GetSpecialValueFor("damage_per_stack") + self.fDamage) * self:GetStackCount())
end

function modifier_bristleback_warpath_custom_stacks:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed_per_stack") * self:GetStackCount()
end

function modifier_bristleback_warpath_custom_stacks:GetModifierModelScale()
    return self:GetStackCount()
end

function modifier_bristleback_warpath_custom_stacks:OnCreated()
    self.damage = 0
    self:SetHasCustomTransmitterData(true)
    self:OnRefresh()
end

function modifier_bristleback_warpath_custom_stacks:OnRefresh()
    if not IsServer() then return end

    self.damage = self:GetCaster():GetStrength() * (self:GetAbility():GetSpecialValueFor("str_damage_pct_per_stack")/100)

    self:InvokeBonusDamage()
end

function modifier_bristleback_warpath_custom_stacks:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_bristleback_warpath_custom_stacks:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_bristleback_warpath_custom_stacks:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function bristleback_warpath_custom:GetIntrinsicModifierName()
    return "modifier_bristleback_warpath_custom"
end

function bristleback_warpath_custom:GetBehavior()
    if self:GetCaster():FindAbilityByName("talent_bristleback_2") ~= nil then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end

    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function bristleback_warpath_custom:GetCooldown()
    local talent = self:GetCaster():FindAbilityByName("talent_bristleback_2")
    if talent ~= nil then
        return talent:GetSpecialValueFor("cooldown")
    end
end

function bristleback_warpath_custom:GetManaCost()
    local talent = self:GetCaster():FindAbilityByName("talent_bristleback_2")
    if talent ~= nil then
        return talent:GetSpecialValueFor("mana_cost")
    end
end

function bristleback_warpath_custom:GetCastRange()
    local talent = self:GetCaster():FindAbilityByName("talent_bristleback_2")
    if talent ~= nil then
        return 150
    end
end

function bristleback_warpath_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_bristleback_2")
    if not talent then return end
    
    local mod = caster:FindModifierByName("modifier_bristleback_warpath_custom_stacks")

    local stacks = 0

    if mod ~= nil then
        stacks = stacks + mod:GetStackCount()
    end

    local damage = talent:GetSpecialValueFor("damage")
    local victim = self:GetCursorTarget()

    local goo = victim:FindModifierByName("modifier_bristleback_viscous_nasal_goo_custom")
    if goo ~= nil then
        stacks = stacks + goo:GetStackCount()
    end

    local quill = victim:FindModifierByName("modifier_bristleback_quill_spray_custom")
    if quill ~= nil then
        stacks = stacks + quill:GetStackCount()
    end

    caster:StartGesture(ACT_DOTA_ATTACK)

    local effect_cast = ParticleManager:CreateParticle( "particles/econ/items/earthshaker/earthshaker_totem_ti6/earthshaker_totem_ti6_blur_v2.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControl( effect_cast, 0, caster:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast )

    local effect_cast2 = ParticleManager:CreateParticle( "particles/econ/items/earthshaker/earthshaker_totem_ti6/earthshaker_totem_ti6_blur_impact_v2.vpcf", PATTACH_POINT_FOLLOW, victim )
    ParticleManager:SetParticleControl( effect_cast2, 0, victim:GetAbsOrigin() )
    ParticleManager:ReleaseParticleIndex( effect_cast2 )

    ApplyDamage({
        victim = victim,
        attacker = caster,
        damage = damage * stacks,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = self
    })

    EmitSoundOn("Hero_EarthShaker.Totem.Attack", victim)

    caster:RemoveModifierByName("modifier_bristleback_warpath_custom_stacks")
    victim:RemoveModifierByName("modifier_bristleback_quill_spray_custom")
    victim:RemoveModifierByName("modifier_bristleback_viscous_nasal_goo_custom")
end

function modifier_bristleback_warpath_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ABILITY_FULLY_CAST  
    }
    return funcs
end

function modifier_bristleback_warpath_custom:OnCreated()
    self.parent = self:GetParent()
end

function modifier_bristleback_warpath_custom:OnAbilityFullyCast(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
        return
    end

    local ability = event.ability
    if not ability then return end
    if ability == self:GetAbility() then return end

    local _ability = parent:FindAbilityByName(ability:GetAbilityName())
    if _ability == nil or _ability:IsNull() then return end

    if parent:HasModifier("modifier_bristleback_warpath_custom_stacks") then
        local mod = parent:FindModifierByName("modifier_bristleback_warpath_custom_stacks")
        if mod:GetStackCount() < self:GetAbility():GetSpecialValueFor("max_stacks") then
            mod:IncrementStackCount()
        end

        mod:ForceRefresh()
    else
        local mod = parent:AddNewModifier(parent, self:GetAbility(), "modifier_bristleback_warpath_custom_stacks", {
            duration = self:GetAbility():GetSpecialValueFor("stack_duration")
        })
        mod:IncrementStackCount()
        mod:ForceRefresh()
    end
end
