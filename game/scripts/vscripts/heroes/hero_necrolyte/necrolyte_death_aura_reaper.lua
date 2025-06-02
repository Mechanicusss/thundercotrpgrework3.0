LinkLuaModifier("modifier_necrolyte_death_aura_reaper", "heroes/hero_necrolyte/necrolyte_death_aura_reaper", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_death_aura_reaper_emitter", "heroes/hero_necrolyte/necrolyte_death_aura_reaper", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_death_aura_reaper_enemy", "heroes/hero_necrolyte/necrolyte_death_aura_reaper", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

necrolyte_death_aura_reaper = class(ItemBaseClass)
modifier_necrolyte_death_aura_reaper = class(necrolyte_death_aura_reaper)
modifier_necrolyte_death_aura_reaper_enemy = class(ItemBaseClassAura)
modifier_necrolyte_death_aura_reaper_emitter = class(ItemBaseClassBuff)
-------------
function necrolyte_death_aura_reaper:GetIntrinsicModifierName()
    return "modifier_necrolyte_death_aura_reaper"
end

function necrolyte_death_aura_reaper:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local ability = self

    if self:GetToggleState() then
        --[[
        local cost = self:GetSpecialValueFor("required_charges")
        local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
        if charges == nil or charges:GetStackCount() < cost then
            DisplayError(caster:GetPlayerID(), "#necrolyte_not_enough_corpse_charges")
            self:EndCooldown()
            self:ToggleAbility()
            return
        end
        --]]

        caster:AddNewModifier(caster, ability, "modifier_necrolyte_death_aura_reaper_emitter", {})
        EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration", caster)
        EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration.Loop", caster)
    else
        caster:RemoveModifierByNameAndCaster("modifier_necrolyte_death_aura_reaper_emitter", caster)
        EmitSoundOn("Hero_WitchDoctor.Voodoo_Restoration.Off", caster)
        StopSoundOn("Hero_WitchDoctor.Voodoo_Restoration.Loop", caster)
    end
end

function necrolyte_death_aura_reaper:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function modifier_necrolyte_death_aura_reaper:OnCreated()
    if not IsServer() then return end
end
---
function modifier_necrolyte_death_aura_reaper_emitter:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect = nil

    self:PlayEffects(parent)

    self:StartIntervalThink(1)
end

function modifier_necrolyte_death_aura_reaper_emitter:OnIntervalThink()
    local caster = self:GetParent()
    local ability = self:GetAbility()

    --[[
    local cost = ability:GetSpecialValueFor("required_charges")
    local charges = caster:FindModifierByNameAndCaster("modifier_necrolyte_corpse_charges_buff_permanent", caster)
    if charges == nil or charges:GetStackCount() < cost then
        DisplayError(caster:GetPlayerID(), "#necrolyte_not_enough_corpse_charges")
        caster:RemoveModifierByNameAndCaster("modifier_necrolyte_death_aura_reaper_emitter", caster)
        ability:ToggleAbility()
        self:StartIntervalThink(-1)
        return
    end

    if charges:GetStackCount() >= cost then
        charges:SetStackCount(charges:GetStackCount()-cost)
    end
    --]]
end

function modifier_necrolyte_death_aura_reaper_emitter:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)
end

function modifier_necrolyte_death_aura_reaper_emitter:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/necrolyte_aura/necrolyte_spirit_ground_projection.vpcf"

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect, 0, target:GetOrigin() )
end

function modifier_necrolyte_death_aura_reaper_emitter:IsAura()
  return true
end

function modifier_necrolyte_death_aura_reaper_emitter:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_necrolyte_death_aura_reaper_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_death_aura_reaper_emitter:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_necrolyte_death_aura_reaper_emitter:GetModifierAura()
    return "modifier_necrolyte_death_aura_reaper_enemy"
end

function modifier_necrolyte_death_aura_reaper_emitter:GetAuraEntityReject(target)
    if not self:GetAbility():IsActivated() then return true end

    return false
end
------------
function modifier_necrolyte_death_aura_reaper_enemy:OnCreated()
    self:SetHasCustomTransmitterData(true)

    self.shred = 0

    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect = nil

    self:PlayEffects(parent)

    local caster = self:GetCaster()

    self.damageTable = {
        victim = parent,
        attacker = caster,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
    }

    self.interval = 0.25

    self:StartIntervalThink(self.interval)

    self:OnRefresh()
end

function modifier_necrolyte_death_aura_reaper_enemy:OnRemoved()
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)
end

function modifier_necrolyte_death_aura_reaper_enemy:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/necrolyte_aura/necrolyte_spirit_debuff.vpcf"

    -- Create Particle
    self.effect = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect,
        0,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )

    ParticleManager:SetParticleControl( self.effect, 0, target:GetOrigin() )
end

function modifier_necrolyte_death_aura_reaper_enemy:OnIntervalThink()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    if not ability or ability == nil then return end -- Ability has been removed
    if not caster:IsAlive() or not parent:IsAlive() then return end
    if parent:GetLevel() > caster:GetLevel() or IsBossTCOTRPG(parent) then return end

    local hpDmg = ability:GetSpecialValueFor("max_hp_damage")

    if caster:HasTalent("special_bonus_unique_necrolyte_4_custom") then
        hpDmg = hpDmg + caster:FindAbilityByName("special_bonus_unique_necrolyte_4_custom"):GetSpecialValueFor("value")
    end
    
    local damage = (parent:GetMaxHealth() * (hpDmg/100))

    self.damageTable.damage = damage * self.interval

    ApplyDamage(self.damageTable)

    self:OnRefresh()
end

function modifier_necrolyte_death_aura_reaper_enemy:OnRefresh()
    if not IsServer() then return end

    local ability = self:GetAbility()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    self.shred = self:GetAbility():GetSpecialValueFor("magic_shred")

    self:InvokeBonusShred()
end

function modifier_necrolyte_death_aura_reaper_enemy:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS 
    }

    return funcs
end

function modifier_necrolyte_death_aura_reaper_enemy:GetModifierMagicalResistanceBonus()
    return self.fShred
end

function modifier_necrolyte_death_aura_reaper_enemy:AddCustomTransmitterData()
    return
    {
        shred = self.fShred,
    }
end

function modifier_necrolyte_death_aura_reaper_enemy:HandleCustomTransmitterData(data)
    if data.shred ~= nil then
        self.fShred = tonumber(data.shred)
    end
end

function modifier_necrolyte_death_aura_reaper_enemy:InvokeBonusShred()
    if IsServer() == true then
        self.fShred = self.shred

        self:SendBuffRefreshToClients()
    end
end