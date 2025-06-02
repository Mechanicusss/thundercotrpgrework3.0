LinkLuaModifier("modifier_bloodseeker_blood_mist_custom", "heroes/hero_bloodseeker/mist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_blood_mist_custom_buff", "heroes/hero_bloodseeker/mist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_blood_mist_custom_stacks", "heroes/hero_bloodseeker/mist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_blood_mist_custom_buff_aura", "heroes/hero_bloodseeker/mist", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_rupture_custom_debuff", "heroes/hero_bloodseeker/rupture", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bloodseeker_blood_mist_custom_self_drain", "heroes/hero_bloodseeker/mist", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassAura = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
}

bloodseeker_blood_mist_custom = class(ItemBaseClass)
modifier_bloodseeker_blood_mist_custom = class(bloodseeker_blood_mist_custom)
modifier_bloodseeker_blood_mist_custom_buff = class(ItemBaseClassBuff)
modifier_bloodseeker_blood_mist_custom_buff_aura = class(ItemBaseClassAura)
modifier_bloodseeker_blood_mist_custom_self_drain = class(ItemBaseClassBuff)
modifier_bloodseeker_blood_mist_custom_stacks = class(ItemBaseClassBuff)
-------------
function bloodseeker_blood_mist_custom:GetIntrinsicModifierName()
    return "modifier_bloodseeker_blood_mist_custom"
end

function bloodseeker_blood_mist_custom:GetHealthCost()
    return self:GetCaster():GetMaxHealth() * (self:GetSpecialValueFor("health_cost_pct")/100)
end

function bloodseeker_blood_mist_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function bloodseeker_blood_mist_custom:OnToggle()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local ability = self

    ability.HPDamage = self:GetHealthCost(-1)

    if self:GetToggleState() then
        caster:AddNewModifier(caster, ability, "modifier_bloodseeker_blood_mist_custom_buff", {})
    else
        caster:RemoveModifierByNameAndCaster("modifier_bloodseeker_blood_mist_custom_buff", caster)
    end
end
------------
function modifier_bloodseeker_blood_mist_custom_buff:DeclareFunctions()
    local funcs = {
         --MODIFIER_EVENT_ON_DEATH
    }

    return funcs
end

function modifier_bloodseeker_blood_mist_custom_buff:OnDeath(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if event.attacker ~= parent then return end

    local ability = self:GetAbility()
    if event.inflictor ~= ability then return end

    local stacks = parent:FindModifierByName("modifier_bloodseeker_blood_mist_custom_stacks")
    if not stacks then
        stacks = parent:AddNewModifier(parent, ability, "modifier_bloodseeker_blood_mist_custom_stacks", {})
    end

    if stacks then
        stacks:IncrementStackCount()
        stacks:ForceRefresh()
    end
end

function modifier_bloodseeker_blood_mist_custom_buff:IsAura() return true end

function modifier_bloodseeker_blood_mist_custom_buff:OnCreated()
    if not IsServer() then return end

    local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_aoe.vpcf"
    local sound_cast = "Hero_Boodseeker.Bloodmist"
    local radius = self:GetAbility():GetSpecialValueFor("radius")

    -- Create Particle
    self.effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
    ParticleManager:SetParticleControl( self.effect_cast, 0, self:GetParent():GetOrigin() )
    ParticleManager:SetParticleControl( self.effect_cast, 1, Vector( radius, radius, radius ) )

    -- Create Sound
    EmitSoundOn( sound_cast, self:GetParent() )

    self:StartIntervalThink(GameRules:GetGameFrameTime())
    self:OnIntervalThink()

    self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_bloodseeker_blood_mist_custom_self_drain", {})
end

function modifier_bloodseeker_blood_mist_custom_buff:OnDestroy()
    if not IsServer() then return end

    ParticleManager:DestroyParticle( self.effect_cast, false )
    ParticleManager:ReleaseParticleIndex( self.effect_cast )

    -- Stop sound
    local sound_cast = "Hero_Boodseeker.Bloodmist"
    StopSoundOn( sound_cast, self:GetParent() )
    self:GetParent():RemoveModifierByNameAndCaster("modifier_bloodseeker_blood_mist_custom_self_drain", self:GetParent())
end

function modifier_bloodseeker_blood_mist_custom_buff:OnIntervalThink()
    ParticleManager:SetParticleControl(self.effect_cast, 0, self:GetParent():GetOrigin())
end

function modifier_bloodseeker_blood_mist_custom_buff:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_CREEP)
end

function modifier_bloodseeker_blood_mist_custom_buff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_bloodseeker_blood_mist_custom_buff:GetAuraRadius()
  return self:GetAbility():GetLevelSpecialValueFor("radius", (self:GetAbility():GetLevel() - 1))
end

function modifier_bloodseeker_blood_mist_custom_buff:GetModifierAura()
    return "modifier_bloodseeker_blood_mist_custom_buff_aura"
end

function modifier_bloodseeker_blood_mist_custom_buff:GetAuraEntityReject(target)
    --if target:GetLevel() > self:GetCaster():GetLevel() then return true end

    return target:IsMagicImmune() -- Do not target magic immune units
end
--
function modifier_bloodseeker_blood_mist_custom_buff_aura:OnCreated()
    if not IsServer() then return end

    self.ability = self:GetAbility()
    self.dmgPct = self.ability:GetSpecialValueFor("max_hp_damage_pct")
    self.interval = self.ability:GetSpecialValueFor("interval")

    self:StartIntervalThink(self.interval)
    self:OnIntervalThink()
end

function modifier_bloodseeker_blood_mist_custom_buff_aura:OnIntervalThink()
    local caster = self:GetCaster()
    local target = self:GetParent()
    if target:IsMagicImmune() then return end

    local dmgHP = ((caster:GetMaxHealth() * (self.dmgPct/100))) 
    --

    local dmg = self:GetAbility():GetSpecialValueFor("damage")
    local stacks = caster:FindModifierByName("modifier_bloodseeker_blood_mist_custom_stacks")
    if stacks ~= nil and stacks:GetStackCount() > 0 then
        dmg = dmg + (stacks:GetStackCount() * self.ability:GetSpecialValueFor("thirst_damage_per_stack"))
    end

    local damageTableFlat = {
        victim = target,
        attacker = caster,
        damage = self.ability.HPDamage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self.ability
    }
    
    ApplyDamage(damageTableFlat)
    
    -- end --

    -- Aghs scepter --
    --[[
    if self:GetCaster():HasScepter() then
        local rupture = self:GetCaster():FindAbilityByName("bloodseeker_rupture_custom")
        if rupture ~= nil and rupture:GetLevel() > 0 then
            local ruptureMaxStacks = rupture:GetSpecialValueFor("max_stacks")
            local ruptureMod = target:FindModifierByNameAndCaster("modifier_bloodseeker_rupture_custom_debuff", self:GetCaster())

            if ruptureMod == nil then
                ruptureMod = target:AddNewModifier(self:GetCaster(), rupture, "modifier_bloodseeker_rupture_custom_debuff", { duration = rupture:GetSpecialValueFor("duration") })
                ruptureMod:SetStackCount(ruptureMaxStacks)
                ruptureMod:ForceRefresh()
            else
                ruptureMod:SetStackCount(ruptureMaxStacks)
                ruptureMod:ForceRefresh()
            end
        end
    end
    --]]
end

function modifier_bloodseeker_blood_mist_custom_buff_aura:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, --GetModifierMoveSpeedBonus_Percentage
    }

    return funcs
end

function modifier_bloodseeker_blood_mist_custom_buff_aura:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("movement_slow")
end
----
function modifier_bloodseeker_blood_mist_custom_self_drain:IsHidden() return true end
function modifier_bloodseeker_blood_mist_custom_self_drain:IsDebuff() return true end

function modifier_bloodseeker_blood_mist_custom_self_drain:OnCreated()
    if not IsServer() then return end

    self.parent = self:GetParent()
    self.ability = self:GetAbility()
    self.interval = self.ability:GetSpecialValueFor("interval")
    self.dmgPct = self.ability:GetSpecialValueFor("max_hp_damage_pct")

    --self:StartIntervalThink(self.interval)
    --self:OnIntervalThink()
end

function modifier_bloodseeker_blood_mist_custom_self_drain:OnIntervalThink()
    local dmgHP = (self.parent:GetMaxHealth() * (self.dmgPct/100)) * self.interval

    -- Self damage
    ApplyDamage({
        victim = self.parent,
        attacker = self.parent,
        damage = dmgHP,
        damage_type = DAMAGE_TYPE_PURE,
        damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION,
    })
end
--------------
function modifier_bloodseeker_blood_mist_custom_stacks:RemoveOnDeath() return false end