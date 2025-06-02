LinkLuaModifier("modifier_phantom_assassin_despair", "heroes/hero_phantom_assassin/phantom_assassin_despair", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phantom_assassin_despair_active", "heroes/hero_phantom_assassin/phantom_assassin_despair", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

phantom_assassin_despair = class(ItemBaseClass)
modifier_phantom_assassin_despair = class(phantom_assassin_despair)
modifier_phantom_assassin_despair_active = class(ItemBaseClassAbsorb)
-------------
function phantom_assassin_despair:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_despair"
end

function phantom_assassin_despair:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local ability = self
    local duration = ability:GetSpecialValueFor("duration")
    
    caster:AddNewModifier(caster, ability, "modifier_phantom_assassin_despair_active", { duration = duration })

    EmitSoundOn("Hero_PhantomAssassin.Blur.Break", caster)
end
------------
function modifier_phantom_assassin_despair_active:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, --GetModifierAttackSpeedBonus_Constant
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }

    return funcs
end

function modifier_phantom_assassin_despair_active:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("attack_speed")
end

function modifier_phantom_assassin_despair_active:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_speed")
end

function modifier_phantom_assassin_despair_active:OnAttackLanded(event)
    if not IsServer() then return end

    if event.attacker ~= self:GetParent() then return end

    local target = event.target
    local attacker = event.attacker
    local ability = self:GetAbility()

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