LinkLuaModifier("modifier_talent_lina_1", "heroes/hero_lina/talents/talent_lina_1", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

talent_lina_1 = class(ItemBaseClass)
modifier_talent_lina_1 = class(talent_lina_1)
-------------
function talent_lina_1:GetIntrinsicModifierName()
    return "modifier_talent_lina_1"
end
-------------
function modifier_talent_lina_1:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE   
    }
end

function modifier_talent_lina_1:GetModifierTotalDamageOutgoing_Percentage(event)
    local caster = self:GetCaster()

    if event.attacker ~= caster then return end

    local parent = self:GetParent()

    if not event.inflictor then return end
    if event.inflictor:GetAbilityName() ~= "lina_sun_ray_custom" then return end

    return self:GetAbility():GetSpecialValueFor("damage_increase_pct")
end

function modifier_talent_lina_1:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()

    local fiery = parent:FindAbilityByName("lina_fiery_soul_custom")
    if fiery ~= nil then
        fiery:SetActivated(false)
    end

    local sunray = parent:FindAbilityByName("lina_sun_ray_custom")
    if sunray ~= nil then
        sunray:SetActivated(true)
    end
end

function modifier_talent_lina_1:OnRemoved()
    if not IsServer() then return end
    local parent = self:GetParent()

    local fiery = parent:FindAbilityByName("lina_fiery_soul_custom")
    if fiery ~= nil then
        fiery:SetActivated(true)
    end

    local sunray = parent:FindAbilityByName("lina_sun_ray_custom")
    if sunray ~= nil then
        sunray:SetActivated(false)
    end
end