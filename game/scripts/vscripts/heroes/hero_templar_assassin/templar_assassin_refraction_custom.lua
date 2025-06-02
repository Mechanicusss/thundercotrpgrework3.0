LinkLuaModifier("modifier_templar_assassin_refraction_custom", "heroes/hero_templar_assassin/templar_assassin_refraction_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_custom_damage", "heroes/hero_templar_assassin/templar_assassin_refraction_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_custom_grace", "heroes/hero_templar_assassin/templar_assassin_refraction_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_templar_assassin_refraction_custom_grace_cd", "heroes/hero_templar_assassin/templar_assassin_refraction_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsStackable = function(self) return true end,
    IsDebuff = function(self) return false end,
}

local ItemBaseClassGrace = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsHidden = function(self) return true end,
}

templar_assassin_refraction_custom = class(ItemBaseClass)
modifier_templar_assassin_refraction_custom = class(templar_assassin_refraction_custom)
modifier_templar_assassin_refraction_custom_damage = class(ItemBaseClass)
modifier_templar_assassin_refraction_custom_grace = class(ItemBaseClassGrace)
modifier_templar_assassin_refraction_custom_grace_cd = class(ItemBaseClassGrace)
-------------
function templar_assassin_refraction_custom:GetIntrinsicModifierName()
    return "modifier_templar_assassin_refraction_custom"
end

function modifier_templar_assassin_refraction_custom:IsHidden()
    return self:GetStackCount() < 1
end

function modifier_templar_assassin_refraction_custom:OnRemoved()
    if not IsServer() then return end 

    local parent = self:GetParent()

    parent:RemoveModifierByName("modifier_templar_assassin_refraction_custom_damage")
    parent:RemoveModifierByName("modifier_templar_assassin_refraction_custom_grace")
    parent:RemoveModifierByName("modifier_templar_assassin_refraction_custom_grace_cd")
end

function modifier_templar_assassin_refraction_custom:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self:GetAbility()

    self.effect_cast = nil

    self.interval = ability:GetSpecialValueFor("restore_time")

    self.changedInterval = false

    local buff = caster:FindModifierByName("modifier_templar_assassin_refraction_custom_damage")
    if buff == nil then
        caster:AddNewModifier(caster, ability, "modifier_templar_assassin_refraction_custom_damage", {})
    end

    self:OnIntervalThink()
    self:StartIntervalThink(self.interval)

    self:PlayEffects(caster)
end

function modifier_templar_assassin_refraction_custom:OnIntervalThink()
    local caster = self:GetCaster()

    if caster:HasTalent("special_bonus_unique_templar_assassin_1_custom") and not self.changedInterval then
        self.changedInterval = true
        self:StartIntervalThink(-1)
        self:StartIntervalThink(self.interval+(caster:FindAbilityByName("special_bonus_unique_templar_assassin_1_custom"):GetSpecialValueFor("value")))
    end
   
    local ability = self:GetAbility()

    if not ability:IsCooldownReady() or not caster:IsAlive() then return end

    local max = ability:GetSpecialValueFor("max_charges")

    if caster:HasModifier("modifier_item_aghanims_shard") then
        max = max * 2
    end

    if self:GetStackCount() < max and not caster:HasModifier("modifier_templar_assassin_refraction_custom_grace") and not caster:HasModifier("modifier_templar_assassin_refraction_custom_grace_cd") then
        self:IncrementStackCount()
    end

    if self:GetStackCount() == 1 then
        self:PlayEffects(caster)
    end

    -- Add damage as separate instances --
    local buff = caster:FindModifierByName("modifier_templar_assassin_refraction_custom_damage")
    if buff == nil then
        caster:AddNewModifier(caster, ability, "modifier_templar_assassin_refraction_custom_damage", {})
    end

    if buff ~= nil and buff:GetStackCount() < max then
        buff:IncrementStackCount()
    end
end

function modifier_templar_assassin_refraction_custom:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_EVENT_ON_DEATH
    }
end

function modifier_templar_assassin_refraction_custom:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then return end

    self:SetStackCount(0)

    local buff = event.unit:FindModifierByName("modifier_templar_assassin_refraction_custom_damage")
    if buff ~= nil then
        buff:SetStackCount(0)
    end
end

function modifier_templar_assassin_refraction_custom:GetAbsoluteNoDamagePhysical(event)
    if self:GetStackCount() > 0 and event.attacker and (event.damage or event.damage_type == DAMAGE_TYPE_PHYSICAL or event.damage_type == DAMAGE_TYPE_PURE) and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS then
        return 1
    end
end

function modifier_templar_assassin_refraction_custom:GetAbsoluteNoDamageMagical(event)
    if self:GetStackCount() > 0 and event.attacker and (event.damage or event.damage_type == DAMAGE_TYPE_PHYSICAL or event.damage_type == DAMAGE_TYPE_PURE) and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS then
        return 1
    end
end

function modifier_templar_assassin_refraction_custom:GetAbsoluteNoDamagePure(event)
    if self:GetStackCount() > 0 and event.attacker and (event.damage or event.damage_type == DAMAGE_TYPE_PHYSICAL or event.damage_type == DAMAGE_TYPE_PURE) and bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= DOTA_DAMAGE_FLAG_HPLOSS then
        self:PlayEffects2(event.target)

        if not event.target:HasTalent("special_bonus_unique_templar_assassin_2_custom") then
            self:DecrementStackCount()
        else
            if not event.target:HasModifier("modifier_templar_assassin_refraction_custom_grace") then
                self:DecrementStackCount()
            end
        end

        if not event.target:HasModifier("modifier_templar_assassin_refraction_custom_grace_cd") and event.target:HasTalent("special_bonus_unique_templar_assassin_2_custom") then
            local duration = event.target:FindAbilityByName("special_bonus_unique_templar_assassin_2_custom"):GetSpecialValueFor("value")
            event.target:AddNewModifier(event.target, self:GetAbility(), "modifier_templar_assassin_refraction_custom_grace", {
                duration = duration
            })
        end

        return 1
    end
end

function modifier_templar_assassin_refraction_custom:OnStackCountChanged()
    if not IsServer() then return end

    if self:GetStackCount() <= 0 then
        self:GetAbility():UseResources(false, false, false, true)

        if self.effect_cast ~= nil then
            ParticleManager:DestroyParticle(self.effect_cast, false)
            ParticleManager:ReleaseParticleIndex(self.effect_cast)
        end
    end
end

function modifier_templar_assassin_refraction_custom:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_templar_assassin_refraction_custom:PlayEffects(target)
    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf"
    local sound_cast = "Hero_TemplarAssassin.Refraction"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    self:AddParticle(self.effect_cast, false, false, -1, true, false)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_templar_assassin_refraction_custom:PlayEffects2(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_templar_assassin/templar_assassin_refract_hit.vpcf"
    local particle_cast_warp = "particles/units/heroes/hero_templar_assassin/templar_assassin_refract_plasma_contact_warp.vpcf"
    local sound_cast = "Hero_TemplarAssassin.Refraction.Absorb"

    local effect_cast_warp = ParticleManager:CreateParticle(particle_cast_warp, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:DestroyParticle(effect_cast_warp, false)
    ParticleManager:ReleaseParticleIndex(effect_cast_warp)

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        2,
        target,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )

    ParticleManager:ReleaseParticleIndex(effect_cast)

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end
------------
function modifier_templar_assassin_refraction_custom_damage:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_templar_assassin_refraction_custom_damage:OnIntervalThink()
    self.damage = self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
    self:InvokeBonusDamage()
end

function modifier_templar_assassin_refraction_custom_damage:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        --MODIFIER_PROPERTY_TOOLTIP,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end

function modifier_templar_assassin_refraction_custom_damage:OnAttackLanded(event)
    if not IsServer() then return end

    if self:GetParent() ~= event.attacker then return end

    if self:GetStackCount() > 0 then
        self:DecrementStackCount()
    end
end

function modifier_templar_assassin_refraction_custom_damage:OnTooltip()
    return (self:GetCaster():GetDamageMin()+self:GetCaster():GetDamageMax()/2) * (self.fDamage/100)
end

function modifier_templar_assassin_refraction_custom_damage:GetModifierDamageOutgoing_Percentage(params)
    if self:GetStackCount() > 0 then
        return self.fDamage
    end
end

function modifier_templar_assassin_refraction_custom_damage:IsHidden()
    return self:GetStackCount() < 1
end

function modifier_templar_assassin_refraction_custom_damage:AddCustomTransmitterData()
    return
    {
        damage = self.fDamage,
    }
end

function modifier_templar_assassin_refraction_custom_damage:HandleCustomTransmitterData(data)
    if data.damage ~= nil then
        self.fDamage = tonumber(data.damage)
    end
end

function modifier_templar_assassin_refraction_custom_damage:InvokeBonusDamage()
    if IsServer() == true then
        self.fDamage = self.damage

        self:SendBuffRefreshToClients()
    end
end
-------------
function modifier_templar_assassin_refraction_custom_grace:OnCreated()
    if not IsServer() then return end

    local duration = self:GetParent():FindAbilityByName("special_bonus_unique_templar_assassin_2_custom"):GetSpecialValueFor("value")

    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_templar_assassin_refraction_custom_grace_cd", {
        duration = duration*2
    })
end