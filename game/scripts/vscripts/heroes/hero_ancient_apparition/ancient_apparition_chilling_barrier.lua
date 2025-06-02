LinkLuaModifier("modifier_ancient_apparition_chilling_barrier", "heroes/hero_ancient_apparition/ancient_apparition_chilling_barrier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_barrier_absorb_state", "heroes/hero_ancient_apparition/ancient_apparition_chilling_barrier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ancient_apparition_chilling_barrier_debuff", "heroes/hero_ancient_apparition/ancient_apparition_chilling_barrier", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return true end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

local ItemBaseClassAbsorb = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return false end,
}

ancient_apparition_chilling_barrier = class(ItemBaseClass)
boss_ancient_apparition_chilling_barrier = ancient_apparition_chilling_barrier
modifier_ancient_apparition_chilling_barrier = class(ancient_apparition_chilling_barrier)
modifier_ancient_apparition_chilling_barrier_absorb_state = class(ItemBaseClassAbsorb)
modifier_ancient_apparition_chilling_barrier_debuff = class(ItemBaseClassDebuff)
-------------
function ancient_apparition_chilling_barrier:GetIntrinsicModifierName()
    return "modifier_ancient_apparition_chilling_barrier"
end

function ancient_apparition_chilling_barrier:OnSpellStart()
    if not IsServer() then return end
--
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local ability = self
    local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))
    
    target:AddNewModifier(caster, ability, "modifier_ancient_apparition_chilling_barrier_absorb_state", { duration = duration })
end

function modifier_ancient_apparition_chilling_barrier:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(1)
end

function modifier_ancient_apparition_chilling_barrier:OnRemoved()
    if not IsServer() then return end

    self:StartIntervalThink(-1)

    local buff = self:GetParent():FindModifierByName("modifier_ancient_apparition_chilling_barrier_absorb_state")
    if buff ~= nil then
        self:GetParent():RemoveModifierByName("modifier_ancient_apparition_chilling_barrier_absorb_state")
    end
end

function modifier_ancient_apparition_chilling_barrier:OnIntervalThink()
    local ability = self:GetAbility()

    if ability:GetAutoCastState() and ability:IsCooldownReady() and self:GetParent():GetMana() >= ability:GetManaCost(-1) then
        SpellCaster:Cast(ability, self:GetParent(), true)
    end
end
------------
function modifier_ancient_apparition_chilling_barrier_absorb_state:DeclareFunctions()
    local funcs = {
        MODIFIER_EVENT_ON_TAKEDAMAGE,
        MODIFIER_EVENT_ON_DEATH,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }

    return funcs
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:OnTakeDamage(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then
        return
    end

    if event.attacker == self:GetParent() then return end

    local ability = self:GetAbility()
    local attacker = event.attacker
    
    attacker:AddNewModifier(event.unit, ability, "modifier_ancient_apparition_chilling_barrier_debuff", {
        duration = ability:GetSpecialValueFor("debuff_duration")
    })
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:OnDeath(event)
    if not IsServer() then return end

    if event.unit ~= self:GetParent() then
        return
    end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:OnCreated(props)
    if not IsServer() then return end

    self.effect_cast = nil

    self:PlayEffects(self:GetParent())

    local parent = self:GetParent()

    if not parent:IsRealHero() then return end

    local ability = self:GetAbility()

    self.accountID = PlayerResource:GetSteamAccountID(parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:OnRemoved(props)
    if not IsServer() then return end

    ParticleManager:DestroyParticle(self.effect_cast, true)
    ParticleManager:ReleaseParticleIndex(self.effect_cast)

    local caster = self:GetParent()

    if not caster:IsRealHero() then return end

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_ancient_apparition_chilling_barrier_absorb_state:PlayEffects(target)
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_crystalmaiden/maiden_shard_frostbite.vpcf"
    local sound_cast = "n_creep_OgreMagi.FrostArmor"

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, target )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        target,
        PATTACH_CENTER_FOLLOW,
        "attach_hitloc",
        target:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl( self.effect_cast, 0, target:GetAbsOrigin() )

    -- Create Sound
    EmitSoundOn( sound_cast, target )
end

function modifier_ancient_apparition_chilling_barrier_debuff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE 
    }

    return funcs
end

function modifier_ancient_apparition_chilling_barrier_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("move_slow")
end

function modifier_ancient_apparition_chilling_barrier_debuff:GetModifierAttackSpeedPercentage()
    return self:GetAbility():GetSpecialValueFor("attack_slow")
end

function modifier_ancient_apparition_chilling_barrier_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_frost_lich.vpcf"
end