LinkLuaModifier("modifier_crystal_maiden_frostbite_custom", "heroes/hero_crystal_maiden/crystal_maiden_frostbite_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_frostbite_custom_debuff", "heroes/hero_crystal_maiden/crystal_maiden_frostbite_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_frostbite_custom_debuff_frozen", "heroes/hero_crystal_maiden/crystal_maiden_frostbite_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_frostbite_custom_debuff_cooldown", "heroes/hero_crystal_maiden/crystal_maiden_frostbite_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return true end,
}

crystal_maiden_frostbite_custom = class(ItemBaseClass)
modifier_crystal_maiden_frostbite_custom = class(crystal_maiden_frostbite_custom)
modifier_crystal_maiden_frostbite_custom_debuff = class(ItemBaseClassDebuff)
modifier_crystal_maiden_frostbite_custom_debuff_frozen = class(ItemBaseClassDebuff)
modifier_crystal_maiden_frostbite_custom_debuff_cooldown = class(ItemBaseClassDebuff)

ICE_ABILITIES = {
    "crystal_maiden_crystal_nova_custom",
    "crystal_maiden_freezing_field_custom",
    "crystal_maiden_blizzard",
    "lich_frost_nova_custom",
    "lich_frost_shield_custom",
    "lich_ice_spire_custom",
    "lich_ice_spire_custom_field",
    "lich_chain_frost_custom",
    "winter_wyvern_arctic_burn",
    "winter_wyvern_splinter_blast",
    "ancient_apparition_chilling_barrier",
    "ancient_apparition_chilling_ground",
    "ancient_apparition_chilling_touch_custom",
    "ancient_apparition_sharp_ice",
    "drow_ranger_frost_arrows_custom",
}
-------------
function crystal_maiden_frostbite_custom:GetIntrinsicModifierName()
    return "modifier_crystal_maiden_frostbite_custom"
end

function modifier_crystal_maiden_frostbite_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE 
    }
    return funcs
end

function modifier_crystal_maiden_frostbite_custom:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local inflictor = event.inflictor

    if parent ~= event.attacker or parent:IsIllusion() or not parent:IsRealHero() or parent:PassivesDisabled() then return end
    if inflictor == nil then return end

    local pass = false

    for _,ability in ipairs(ICE_ABILITIES) do
        if ability == inflictor:GetAbilityName() then
            pass = true
        end
    end

    if not pass then return end

    local victim = event.unit
    local ability = self:GetAbility()

    --if victim:HasModifier("modifier_crystal_maiden_frostbite_custom_debuff_frozen") then return end

    local debuff = victim:FindModifierByName("modifier_crystal_maiden_frostbite_custom_debuff")
    if debuff == nil then
        debuff = victim:AddNewModifier(parent, ability, "modifier_crystal_maiden_frostbite_custom_debuff", {
            duration = ability:GetSpecialValueFor("duration")
        })
    end

    if debuff ~= nil then
        if debuff:GetStackCount() < ability:GetSpecialValueFor("max_stacks") then
            debuff:IncrementStackCount()
        elseif debuff:GetStackCount() >= ability:GetSpecialValueFor("max_stacks") and not victim:HasModifier("modifier_crystal_maiden_frostbite_custom_debuff_frozen") and not victim:HasModifier("modifier_crystal_maiden_frostbite_custom_debuff_cooldown") then
            victim:AddNewModifier(parent, ability, "modifier_crystal_maiden_frostbite_custom_debuff_frozen", {
                duration = ability:GetSpecialValueFor("duration")
            })
        end

        debuff:ForceRefresh()
    end
end
--------
function modifier_crystal_maiden_frostbite_custom_debuff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_crystal_maiden_frostbite_custom_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

    return funcs
end

function modifier_crystal_maiden_frostbite_custom_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow") * self:GetStackCount()
end


function modifier_crystal_maiden_frostbite_custom_debuff:GetModifierIncomingDamage_Percentage(event)
    local parent = self:GetParent()
    local caster = self:GetCaster()

    local inflictor = event.inflictor
    if inflictor == nil then return end

    local pass = false

    for _,ability in ipairs(ICE_ABILITIES) do
        if ability == inflictor:GetAbilityName() then
            pass = true
        end
    end

    if not pass then return end
    local ability = self:GetAbility()
    local amp = ability:GetSpecialValueFor("damage_amp") * self:GetStackCount()

    return amp
end

function modifier_crystal_maiden_frostbite_custom_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end
-------------
function modifier_crystal_maiden_frostbite_custom_debuff_frozen:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_crystal_maiden_frostbite_custom_debuff_frozen:CheckState()
    local state = {
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true
    }

    return state
end

function modifier_crystal_maiden_frostbite_custom_debuff_frozen:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf", PATTACH_WORLDORIGIN, parent)
    ParticleManager:SetParticleControl(self.vfx, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.vfx, 1, parent:GetAbsOrigin())

    EmitSoundOn("hero_Crystal.frostbite", self:GetParent())
end

function modifier_crystal_maiden_frostbite_custom_debuff_frozen:OnRemoved()
    if not IsServer() then return end

    if self.vfx ~= nil then
        ParticleManager:DestroyParticle(self.vfx, true)
        ParticleManager:ReleaseParticleIndex(self.vfx)
    end

    local parent = self:GetParent()
    parent:AddNewModifier(parent, self:GetAbility(), "modifier_crystal_maiden_frostbite_custom_debuff_cooldown", {
        duration = self:GetAbility():GetSpecialValueFor("cooldown")
    })
end

function modifier_crystal_maiden_frostbite_custom_debuff_frozen:GetModifierMagicalResistanceBonus()
    return self:GetAbility():GetSpecialValueFor("magic_res")
end