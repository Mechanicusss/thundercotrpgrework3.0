LinkLuaModifier("modifier_boss_spider_hunger", "heroes/bosses/spider/boss_spider_hunger", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}


boss_spider_hunger = class(ItemBaseClass)
modifier_boss_spider_hunger = class(boss_spider_hunger)
-------------
function boss_spider_hunger:GetIntrinsicModifierName()
    return "modifier_boss_spider_hunger"
end
-------------
function modifier_boss_spider_hunger:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_DEATH
    }
    return funcs
end

function modifier_boss_spider_hunger:GetEffectName()
    return "particles/units/heroes/hero_broodmother/broodmother_hunger_buff.vpcf"
end

function modifier_boss_spider_hunger:OnDeath(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end 

    local ability = self:GetAbility()
    local heal = ability:GetSpecialValueFor("heal_on_kill_pct")
    local amount = parent:GetMaxHealth()*(heal/100)

    parent:Heal(amount, nil)

    SendOverheadEventMessage(parent, OVERHEAD_ALERT_HEAL, parent, amount, nil)

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_explode.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_boss_spider_hunger:OnAttackLanded(event)
    if not IsServer() then return end

    local attacker = event.attacker
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if attacker ~= parent then
        return
    end

    if not caster:IsAlive() or caster:PassivesDisabled() then
        return
    end

    local ability = self:GetAbility()
    
    local lifestealAmount = ability:GetSpecialValueFor("lifesteal")

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