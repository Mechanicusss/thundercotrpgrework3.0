LinkLuaModifier("modifier_dark_willow_shadow_realm_custom", "heroes/hero_dark_willow/dark_willow_shadow_realm_custom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_willow_shadow_realm_custom_buff", "heroes/hero_dark_willow/dark_willow_shadow_realm_custom.lua", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

dark_willow_shadow_realm_custom = class(ItemBaseClass)
modifier_dark_willow_shadow_realm_custom = class(dark_willow_shadow_realm_custom)
modifier_dark_willow_shadow_realm_custom_buff = class(ItemBaseClassBuff)
-------------
function dark_willow_shadow_realm_custom:GetIntrinsicModifierName()
    return "modifier_dark_willow_shadow_realm_custom"
end
-------------
function modifier_dark_willow_shadow_realm_custom:OnDestroy()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_dark_willow_shadow_realm_custom_buff")

    for _,pindx in pairs(self.records) do
        ParticleManager:DestroyParticle(pindx, false)
        ParticleManager:ReleaseParticleIndex(pindx)
    end

    self.records = {}
end

function modifier_dark_willow_shadow_realm_custom:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_START,
        MODIFIER_EVENT_ON_ATTACK_CANCELLED,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY
    }
end

function modifier_dark_willow_shadow_realm_custom:OnAttackRecordDestroy(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local record = self:GetRecord(event.record)

	if not record then return end

    local effect = record
    ParticleManager:DestroyParticle(effect, false)
    ParticleManager:ReleaseParticleIndex(effect)

    self:SetRecord(event.record, nil)
end

function modifier_dark_willow_shadow_realm_custom:SetRecord(key, value)
    self.records[key] = value
end

function modifier_dark_willow_shadow_realm_custom:GetRecord(key)
    return self.records[key]
end

function modifier_dark_willow_shadow_realm_custom:RollChance(chance)
    local rand = math.random()

    if rand < chance / 100 then
        return true
    end

    return false
end

function modifier_dark_willow_shadow_realm_custom:OnCreated()
    self.proc = false
    self.records = {}
end

function modifier_dark_willow_shadow_realm_custom:OnAttackStart()
    local ability = self:GetAbility()
    local parent = self:GetParent()

    local chance = ability:GetSpecialValueFor("chance")
    local duration = ability:GetSpecialValueFor("duration")

    if parent:HasModifier("modifier_dark_willow_shadow_realm_custom_buff") or not self:RollChance(chance) then return end 

    self.proc = true
end

function modifier_dark_willow_shadow_realm_custom:OnAttack()
    if not self.proc then return end

    self.proc = false

    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    local duration = ability:GetSpecialValueFor("duration")

    if not ability:IsCooldownReady() then return end

    parent:AddNewModifier(parent, ability, "modifier_dark_willow_shadow_realm_custom_buff", { duration = duration })

    EmitSoundOn("Hero_DarkWillow.Shadow_Realm", parent)

    ability:UseResources(false, false, false, true)
end

function modifier_dark_willow_shadow_realm_custom:OnAttackCancelled()
    self.proc = false
end
----------------
function modifier_dark_willow_shadow_realm_custom_buff:GetPriority() return 999 end 

function modifier_dark_willow_shadow_realm_custom_buff:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.mod = parent:FindModifierByName("modifier_dark_willow_shadow_realm_custom")
end

function modifier_dark_willow_shadow_realm_custom_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PROJECTILE_NAME,
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }
end

function modifier_dark_willow_shadow_realm_custom_buff:GetModifierProjectileName()
    return "particles/arena/invisiblebox.vpcf"
end

function modifier_dark_willow_shadow_realm_custom_buff:GetEffectName()
    return "particles/units/heroes/hero_dark_willow/dark_willow_shadow_realm.vpcf"
end

function modifier_dark_willow_shadow_realm_custom_buff:GetModifierAttackSpeedPercentage()
    if self:GetParent():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("scepter_attack_speed")
    end
end

function modifier_dark_willow_shadow_realm_custom_buff:GetModifierSpellAmplify_Percentage()
    if self:GetParent():HasScepter() then
        return self:GetAbility():GetSpecialValueFor("scepter_spell_amp") * self:GetElapsedTime()
    end
end

function modifier_dark_willow_shadow_realm_custom_buff:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

function modifier_dark_willow_shadow_realm_custom_buff:OnAttack(event)
    if not IsServer() then return end 

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 
    if parent:IsIllusion() then return end

    if not self.mod then return end

    local ability = self:GetAbility()
    local maxDamageDuration = ability:GetSpecialValueFor("max_damage_duration")
    local pattern = "attach_attack1"

    if RollPercentage(50) then
        pattern = "attach_attack2"
    end

    local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_shadow_attack.vpcf"
    local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        pattern,
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl(effect_cast, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(effect_cast, 2, Vector(parent:GetProjectileSpeed(), 0, 0))
    ParticleManager:SetParticleControl(effect_cast, 5, Vector(self:GetElapsedTime() / maxDamageDuration, 0, 0))

    if self.mod then
        self.mod:SetRecord(event.record, effect_cast)
    end

    EmitSoundOn("Hero_DarkWillow.Shadow_Realm.Attack", parent)
end

function modifier_dark_willow_shadow_realm_custom_buff:OnAttackLanded(event)
    if not IsServer() then return end 

    if not self.mod then return end

    if not self.mod:GetRecord(event.record) then return end

    local parent = self:GetParent()

    if parent ~= event.attacker then return end

    local target = event.target 

    if not IsCreepTCOTRPG(target) and not IsBossTCOTRPG(target) then return end 

    local ability = self:GetAbility()
    local damage = ability:GetSpecialValueFor("damage") + (parent:GetAverageTrueAttackDamage(parent) * (ability:GetSpecialValueFor("attack_to_damage")/100))
    local maxDamageDuration = ability:GetSpecialValueFor("max_damage_duration")
    local damageTimeScaling = ability:GetSpecialValueFor("damage_increase_psec")

    damage = damage * (1+((math.min(self:GetElapsedTime(), maxDamageDuration) * (damageTimeScaling/100))))

    ApplyDamage({
        attacker = parent,
        victim = target,
        damage_type = ability:GetAbilityDamageType(),
        damage = damage,
        ability = ability
    })

    EmitSoundOn("Hero_DarkWillow.Shadow_Realm.Damage", target)
end
