LinkLuaModifier("modifier_boss_skafian_wolf_bite", "heroes/bosses/forest/boss_skafian_wolf_bite", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return true end,
}

boss_skafian_wolf_bite = class(ItemBaseClass)
modifier_boss_skafian_wolf_bite = class(boss_skafian_wolf_bite)
-------------
function boss_skafian_wolf_bite:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    if not target or target == nil then return end

    if target:HasModifier("modifier_boss_skafian_wolf_bite") then
        target:RemoveModifierByName("modifier_boss_skafian_wolf_bite")
    end

    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_boss_skafian_wolf_bite", {
        duration = duration
    })

    EmitSoundOn("Lycan_Wolf.Attack", target)
    EmitSoundOn("hero_bloodseeker.rupture.cast", target)
    EmitSoundOn("hero_bloodseeker.rupture", target)

    local particle = ParticleManager:CreateParticle("particles/abilities/rupture_burst.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(particle)
end
------------
function modifier_boss_skafian_wolf_bite:DeclareFunctions()
    return {
         MODIFIER_EVENT_ON_ATTACK_LANDED,
         MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
end

function modifier_boss_skafian_wolf_bite:GetModifierMoveSpeedBonus_Percentage()
    if self:GetParent():IsMagicImmune() then return 0 end
    return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_boss_skafian_wolf_bite:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    EmitSoundOn("hero_bloodseeker.rupture_FP", parent)

    if (parent:GetHealthPercent() < self:GetAbility():GetSpecialValueFor("threshold")) and not parent:IsMagicImmune() then
        parent:Kill(self:GetAbility(), self:GetCaster())
        EmitSoundOn("Hero_ObsidianDestroyer.AstralImprisonment.End", parent)
        return
    end

    local interval = self:GetAbility():GetSpecialValueFor("interval")

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = parent,
        damage_type = DAMAGE_TYPE_MAGICAL,
        damage = parent:GetMaxHealthTCOTRPG() * (self:GetAbility():GetSpecialValueFor("hp_bleed_pct")/100) * interval,
        ability = self:GetAbility()
    }

    self:StartIntervalThink(interval)
end

function modifier_boss_skafian_wolf_bite:OnIntervalThink()
    local parent = self:GetParent()

    if parent:IsMoving() and not parent:IsMagicImmune() then
        ApplyDamage(self.damageTable)
    end
end

function modifier_boss_skafian_wolf_bite:OnDestroy()
    if not IsServer() then return end

    local parent = self:GetParent()

    StopSoundOn("hero_bloodseeker.rupture_FP", parent)
end

function modifier_boss_skafian_wolf_bite:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local victim = event.target

    if event.attacker ~= caster then return end
    if victim ~= parent then return end
    if event.target == event.attacker then return end

    local ability = self:GetAbility()
    
    local heal = event.damage * (ability:GetSpecialValueFor("lifesteal")/100)
    caster:Heal(heal, ability)

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal, nil)

    local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_boss_skafian_wolf_bite:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end