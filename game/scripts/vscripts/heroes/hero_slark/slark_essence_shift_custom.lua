LinkLuaModifier("modifier_slark_essence_shift_custom", "heroes/hero_slark/slark_essence_shift_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_essence_shift_custom_creeps", "heroes/hero_slark/slark_essence_shift_custom", LUA_MODIFIER_MOTION_NONE)

slark_essence_shift_custom = class({})

function slark_essence_shift_custom:GetIntrinsicModifierName()
    return "modifier_slark_essence_shift_custom"
end

modifier_slark_essence_shift_custom = class({})

function modifier_slark_essence_shift_custom:OnCreated(keys)
    if IsServer() then
        self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_slark_essence_shift_custom_creeps", {})
    end
end

function modifier_slark_essence_shift_custom:OnDestroy()
    if IsServer() then
        self:GetParent():RemoveModifierByName("modifier_slark_essence_shift_custom_creeps")
    end
end

function modifier_slark_essence_shift_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_PROPERTY_TOOLTIP2
    }
end

function modifier_slark_essence_shift_custom:OnDeath(event)
    local parent = self:GetParent()

    if event.attacker ~= parent then return end
    if event.unit == parent then return end

    local modifier = parent:FindModifierByName("modifier_slark_essence_shift_custom_creeps")
    if modifier == nil then
        modifier = parent:AddNewModifier(parent, self:GetAbility(), "modifier_slark_essence_shift_custom_creeps", {})
    end

    if IsBossTCOTRPG(event.unit) then
       self:IncrementStackCount()
    elseif IsCreepTCOTRPG(event.unit) then
        modifier:IncrementStackCount()

        if modifier:GetStackCount() >= self:GetAbility():GetSpecialValueFor("creep_to_agi") then
            modifier:SetStackCount(0)

            self:IncrementStackCount()
        end
    end

    self:PlayEffects(event.unit)
end

function modifier_slark_essence_shift_custom:GetModifierBonusStats_Agility()
    local stacks = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("agi_gain")

    if self.lock then return end

    self.lock = true
    local agi = self:GetCaster():GetAgility()
    self.lock = false

    local bonus = agi / 100 * self:GetAbility():GetSpecialValueFor("bonus_agi_pct")

    return stacks + bonus
end

function modifier_slark_essence_shift_custom:PlayEffects(target)
	local effect_cast = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_essence_shift.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(effect_cast, 1, self:GetParent():GetOrigin() + Vector(0, 0, 64))
	ParticleManager:ReleaseParticleIndex(effect_cast)
end

modifier_slark_essence_shift_custom_creeps = class({
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end
})

function modifier_slark_essence_shift_custom_creeps:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_slark_essence_shift_custom_creeps:OnTooltip()
    return self:GetAbility():GetSpecialValueFor("creep_to_agi")
end