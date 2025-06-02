LinkLuaModifier("modifier_talent_spectre_2", "heroes/hero_spectre/talents/talent_spectre_2", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_talent_spectre_2_spectral_dagger_cooldown", "heroes/hero_spectre/talents/talent_spectre_2", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_spectre_2 = class(ItemBaseClass)
modifier_talent_spectre_2 = class(talent_spectre_2)
modifier_talent_spectre_2_spectral_dagger_cooldown = class(talent_spectre_2)
-------------
function talent_spectre_2:GetIntrinsicModifierName()
    return "modifier_talent_spectre_2"
end
-------------
function modifier_talent_spectre_2:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
end

function modifier_talent_spectre_2:OnTakeDamage(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.unit

    if not event.attacker then return end
    if not IsCreepTCOTRPG(event.attacker) and not IsBossTCOTRPG(event.attacker) then return end
    if parent ~= target or parent == event.attacker then return end
    if ability:GetLevel() < 2 then return end
    if parent:HasModifier("modifier_talent_spectre_2_spectral_dagger_cooldown") then return end

    local dispersion = parent:FindAbilityByName("spectre_dispersion_custom")
    if not dispersion or (dispersion ~= nil and dispersion:GetLevel() < 1) then return end

    local spectralDaggers = parent:FindAbilityByName("spectre_spectral_dagger_custom")
    if not spectralDaggers or (spectralDaggers ~= nil and spectralDaggers:GetLevel() < 1) then return end

    local chance = ability:GetSpecialValueFor("spectral_dagger_chance") 
    if not RollPercentage(chance) then return end

    spectralDaggers:CreateSingleDagger(event.attacker)

    parent:AddNewModifier(parent, ability, "modifier_talent_spectre_2_spectral_dagger_cooldown", {
        duration = ability:GetSpecialValueFor("spectral_dagger_cooldown")
    })
end

function modifier_talent_spectre_2:OnCreated()
    if not IsServer() then return end
end


function modifier_talent_spectre_2:OnDestroy()
    if not IsServer() then return end
end