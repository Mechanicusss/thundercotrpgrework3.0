LinkLuaModifier("modifier_saber_invisible_air", "heroes/hero_saber/invisible_air", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saber_invisible_air_stacks", "heroes/hero_saber/invisible_air", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_saber_invisible_air_debuff", "heroes/hero_saber/invisible_air", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassStacks = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

saber_invisible_air = class(ItemBaseClass)
modifier_saber_invisible_air = class(saber_invisible_air)
modifier_saber_invisible_air_stacks = class(ItemBaseClassStacks)
modifier_saber_invisible_air_debuff = class(ItemBaseClassDebuff)
-------------
function saber_invisible_air:GetIntrinsicModifierName()
    return "modifier_saber_invisible_air"
end

function modifier_saber_invisible_air:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK 
    }
    return funcs
end

function modifier_saber_invisible_air:OnCreated()
    if not IsServer() then return end
    
    local parent = self:GetParent()
    local ability = self:GetAbility()

    parent:AddNewModifier(parent, ability, "modifier_saber_invisible_air_stacks", {})
end

function modifier_saber_invisible_air:OnRemoved()
    if not IsServer() then return end
    
    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_saber_invisible_air_stacks")
end

function modifier_saber_invisible_air:OnAttack(event)
    local unit = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if unit ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()

    if not RollPercentage(ability:GetSpecialValueFor("chance")) then return end

    caster:EmitSound("Arena.Hero_Saber.InvisibleAir")

    local damage = caster:GetAverageTrueAttackDamage(caster) * (ability:GetSpecialValueFor("damage_from_attack")/100)
    local modifier = caster:FindModifierByName("modifier_saber_invisible_air_stacks")

    if modifier then
        local count = modifier:GetStackCount()
        if count > 0 then
            damage = damage * count
        end
    end

    local teamFilter = ability:GetAbilityTargetTeam()
    local typeFilter = ability:GetAbilityTargetType()
    local flagFilter = ability:GetAbilityTargetFlags()
    local teamNumber = caster:GetTeamNumber()
    local position = caster:GetAbsOrigin() + caster:GetForwardVector() * ability:GetSpecialValueFor("forward_offset")
    local radius = ability:GetSpecialValueFor("aoe_radius")
    for _,v in ipairs(FindUnitsInRadius(teamNumber, position, nil, radius, teamFilter, typeFilter, flagFilter, FIND_ANY_ORDER, false)) do
        local debuff = v:FindModifierByName("modifier_saber_invisible_air_debuff")
        if debuff == nil then
            debuff = v:AddNewModifier(caster, ability, "modifier_saber_invisible_air_debuff", {
                duration = ability:GetSpecialValueFor("armor_shred_duration")
            })
        end

        if debuff ~= nil then
            if debuff:GetStackCount() < ability:GetSpecialValueFor("armor_shred_max_stacks") then
                debuff:IncrementStackCount()
            end
            
            debuff:ForceRefresh()
        end

        ApplyDamage({
            victim = v,
            attacker = caster,
            damage = damage,
            damage_type = ability:GetAbilityDamageType(),
            ability = ability
        })
    end

    if modifier then
        modifier.stacks = 0
        modifier:SetStackCount(1)
    end

    local pfx = ParticleManager:CreateParticle("particles/arena/units/heroes/hero_saber/invisible_air.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(pfx, 0, position)
    ParticleManager:SetParticleControl(pfx, 1, Vector(radius))
end

-------------
function modifier_saber_invisible_air_stacks:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

function modifier_saber_invisible_air_stacks:OnIntervalThink()
    local ability = self:GetAbility()
    self.stacks = math.min((self.stacks or 0) + ability:GetSpecialValueFor("damage_per_second") * 0.1, ability:GetSpecialValueFor("damage_max"))
    self:SetStackCount(self.stacks)
end

function modifier_saber_invisible_air_stacks:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_saber_invisible_air_stacks:OnTooltip()
    return self:GetStackCount()
end
function modifier_saber_invisible_air_stacks:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end
-------------
function modifier_saber_invisible_air_debuff:DeclareFunctions()
    return {MODIFIER_PROPERTY_TOOLTIP,MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_saber_invisible_air_debuff:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("armor_shred") * self:GetStackCount()
end
function modifier_saber_invisible_air_debuff:GetModifierPhysicalArmorBonus()
    return self:GetAbility():GetSpecialValueFor("armor_shred") * self:GetStackCount()
end
function modifier_saber_invisible_air_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end