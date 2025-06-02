LinkLuaModifier("modifier_spell_lifesteal_uba", "modifiers/modifier_spell_lifesteal_uba", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseBuffClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return true end,
}

spell_lifesteal_uba = class(ItemBaseClass)
modifier_spell_lifesteal_uba = class(ItemBaseBuffClass)

-----------------
function spell_lifesteal_uba:GetIntrinsicModifierName()
    return "modifier_spell_lifesteal_uba"
end
-----------------

function modifier_spell_lifesteal_uba:OnCreated()
    if not IsServer() then return end
end

function modifier_spell_lifesteal_uba:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_SPENT_MANA,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }

    return funcs
end

function modifier_spell_lifesteal_uba:OnTakeDamage(event)
    if not IsServer() then return end
    
    if event.attacker == self:GetParent() and not event.unit:IsBuilding() and not event.unit:IsOther() then
        if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self and (event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL or event.damage_type == DAMAGE_TYPE_MAGICAL) and event.inflictor and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL and event.damage_flags ~= 1280 then
            local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, event.attacker)
            ParticleManager:ReleaseParticleIndex(particle)

            if not event.attacker:IsAlive() or event.attacker:GetHealth() < 1 then return end
            
            if event.unit:IsCreep() then
                local lifestealCreep = self:GetAbility():GetSpecialValueFor("creep_lifesteal")
                local healAmount = math.max(event.damage, 0) * lifestealCreep * 0.01
                if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                    healAmount = self:GetParent():GetMaxHealth()
                end
                event.attacker:Heal(healAmount, event.attacker)
            else
                local lifestealHero = self:GetAbility():GetSpecialValueFor("hero_lifesteal")
                local healAmount = math.max(event.damage, 0) * lifestealHero * 0.01
                if healAmount < 0 or healAmount > INT_MAX_LIMIT then
                    healAmount = self:GetParent():GetMaxHealth()
                end
                event.attacker:Heal(healAmount, event.attacker)
            end
        end
    end
end

function modifier_spell_lifesteal_uba:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
