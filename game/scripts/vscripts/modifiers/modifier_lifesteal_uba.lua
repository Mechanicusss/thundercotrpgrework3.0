LinkLuaModifier("modifier_lifesteal_uba", "modifiers/modifier_lifesteal_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

lifesteal_uba = class(ItemBaseClass)
modifier_lifesteal_uba = class(lifesteal_uba)

-----------------
function lifesteal_uba:GetIntrinsicModifierName()
    return "modifier_lifesteal_uba"
end
-----------------
function modifier_lifesteal_uba:OnCreated()
    if not IsServer() then return end
end

function modifier_lifesteal_uba:OnRemoved()
    if not IsServer() then return end
end

function modifier_lifesteal_uba:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_lifesteal_uba:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker

    if self:GetParent() ~= attacker then
        return
    end

    local lifestealAmount = self:GetAbility():GetSpecialValueFor("lifesteal")

    if lifestealAmount < 1 or not attacker:IsAlive() or attacker:GetHealth() < 1 or event.target:IsOther() or event.target:IsBuilding() then
        return
    end

    local heal = event.damage * (lifestealAmount/100)

    --local heal = attacker:GetLevel() + self.lifestealAmount

    if attacker:IsIllusion() then -- Illusions only heal for 10% of the value
        heal = heal * 0.1
    end
    
    --attacker:SetHealth(attacker:GetHealth() + heal) DO NOT USE! Ignores regen reduction
    if heal < 0 or heal > INT_MAX_LIMIT then
        heal = self:GetParent():GetMaxHealth()
    end
    attacker:Heal(heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_lifesteal_uba:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
