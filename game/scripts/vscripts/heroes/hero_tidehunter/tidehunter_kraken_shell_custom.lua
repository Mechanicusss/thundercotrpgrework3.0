LinkLuaModifier("modifier_tidehunter_kraken_shell_custom", "heroes/hero_tidehunter/tidehunter_kraken_shell_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

tidehunter_kraken_shell_custom = class(ItemBaseClass)
modifier_tidehunter_kraken_shell_custom = class(tidehunter_kraken_shell_custom)
-------------
function tidehunter_kraken_shell_custom:GetIntrinsicModifierName()
    return "modifier_tidehunter_kraken_shell_custom"
end

function tidehunter_kraken_shell_custom:GetCooldown()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_tidehunter_2")
    if talent ~= nil and talent:GetLevel() > 0 then
        return 0
    end

    return self.BaseClass.GetCooldown(self, -1)
end

function tidehunter_kraken_shell_custom:OnProjectileHit(target, loc)
    if not target then return end 
    if target:IsNull() then return end
    if not target:IsAlive() then return end

    if target:IsMagicImmune() then return end

    local damageType = self:GetAbilityDamageType()
    local caster = self:GetCaster()
    local talent = caster:FindAbilityByName("talent_tidehunter_2")
    if talent ~= nil and talent:GetLevel() > 2 then
        damageType = DAMAGE_TYPE_PURE
    end

    ApplyDamage({
        attacker = self:GetCaster(),
        victim = target,
        damage = self:GetCaster():GetMaxHealth() * (self:GetSpecialValueFor("max_hp_damage")/100),
        damage_type = damageType,
        ability = self
    })

    if self:GetCaster():HasModifier("modifier_item_aghanims_shard") then
        target:AddNewModifier(self:GetCaster(), nil, "modifier_stunned", {
            duration = self:GetSpecialValueFor("stun_duration")
        })
        
        EmitSoundOn("Hero_Tidehunter.ArmsOfTheDeep.Stun", target)
    end
end
------------
function modifier_tidehunter_kraken_shell_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_tidehunter_kraken_shell_custom:OnCreated()
    if not IsServer() then return end 

    self.damageTaken = 0
end

function modifier_tidehunter_kraken_shell_custom:OnTakeDamage(event)
    if not IsServer() then return end 

    local parent = self:GetParent()
    local unit = event.unit 

    if parent ~= unit then return end 

    local attacker = event.attacker 

    if parent == attacker then return end

    if not IsCreepTCOTRPG(attacker) and not IsBossTCOTRPG(attacker) then return end
    
    self.damageTaken = self.damageTaken + event.damage

    local ability = self:GetAbility()

    if not ability:IsCooldownReady() then return end

    local threshold = ability:GetSpecialValueFor("damage_threshold_pct")
    local radius = ability:GetSpecialValueFor("radius")
    local speed = ability:GetSpecialValueFor("speed")
    local maxDistance = ability:GetSpecialValueFor("max_distance")

    if self.damageTaken < (parent:GetMaxHealth() * (threshold/100)) then return end

    self.damageTaken = 0

    parent:Purge(false, true, false, true, false)

    local vfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(vfx, 0, parent:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(vfx)

    EmitSoundOn("Hero_Tidehunter.KrakenShell", parent)

    local direction = (attacker:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized()

    local proj = {
        vSpawnOrigin = parent:GetAbsOrigin(),
        vVelocity = direction * speed,
        fDistance = maxDistance,
        fStartRadius = radius,
        fEndRadius = radius,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO,DOTA_UNIT_TARGET_CREEP,DOTA_UNIT_TARGET_BASIC),
        EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_arm_of_the_deep_projectile.vpcf",
        Ability = ability,
        Source = parent,
        bProvidesVision = true,
        iVisionRadius = radius,
        fVisionDuration = 1,
        iVisionTeamNumber = parent:GetTeamNumber()
    }

    ProjectileManager:CreateLinearProjectile(proj)

    EmitSoundOn("Hero_Tidehunter.ArmsOfTheDeep", parent)

    ability:UseResources(false, false, false, true)
end

function modifier_tidehunter_kraken_shell_custom:GetModifierPhysical_ConstantBlock(event)
    if event.target ~= self:GetParent() or bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end
    
    return event.damage * (self:GetAbility():GetSpecialValueFor("passive_damage_block_pct")/100)
end