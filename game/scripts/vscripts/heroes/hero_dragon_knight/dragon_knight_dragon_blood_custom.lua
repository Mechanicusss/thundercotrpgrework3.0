LinkLuaModifier("modifier_dragon_knight_dragon_blood_custom", "heroes/hero_dragon_knight/dragon_knight_dragon_blood_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_blood_custom_poison_debuff", "heroes/hero_dragon_knight/dragon_knight_dragon_blood_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_blood_custom_fire_shield", "heroes/hero_dragon_knight/dragon_knight_dragon_blood_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dragon_knight_dragon_blood_custom_fire_shield_aura", "heroes/hero_dragon_knight/dragon_knight_dragon_blood_custom", LUA_MODIFIER_MOTION_NONE)

local ItemBaseClass = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return false end,
    IsHidden = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return true end,
    IsStackable = function(self) return false end,
}

local ItemBaseClassBuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsDebuff = function(self) return false end,
    IsStackable = function(self) return false end,
}

dragon_knight_dragon_blood_custom = class(ItemBaseClass)
modifier_dragon_knight_dragon_blood_custom = class(dragon_knight_dragon_blood_custom)
modifier_dragon_knight_dragon_blood_custom_poison_debuff = class(ItemBaseClassDebuff)
modifier_dragon_knight_dragon_blood_custom_fire_shield = class(ItemBaseClassBuff)
modifier_dragon_knight_dragon_blood_custom_fire_shield_aura = class(ItemBaseClassDebuff)
-------------
function dragon_knight_dragon_blood_custom:GetIntrinsicModifierName()
    return "modifier_dragon_knight_dragon_blood_custom"
end

function modifier_dragon_knight_dragon_blood_custom:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, --GetModifierHealthRegenPercentage
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, --GetModifierPhysicalArmorBonus 
        MODIFIER_PROPERTY_EVASION_CONSTANT, --GetModifierEvasion_Constant
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
    return funcs
end

function modifier_dragon_knight_dragon_blood_custom:GetModifierEvasion_Constant()
    return self.fEvasion
end

function modifier_dragon_knight_dragon_blood_custom:GetModifierHealthRegenPercentage()
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_dragon_knight_2_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self:GetAbility():GetSpecialValueFor("max_hp_regen") * ab:GetSpecialValueFor("value")
    end

    return self:GetAbility():GetSpecialValueFor("max_hp_regen")
end

function modifier_dragon_knight_dragon_blood_custom:GetModifierPhysicalArmorBonus()
    local ab = self:GetCaster():FindAbilityByName("special_bonus_unique_dragon_knight_2_custom")
    if ab ~= nil and ab:GetLevel() > 0 then
        return self:GetAbility():GetSpecialValueFor("armor") * ab:GetSpecialValueFor("value")
    end
    
    return self:GetAbility():GetSpecialValueFor("armor")
end

function modifier_dragon_knight_dragon_blood_custom:AddCustomTransmitterData()
    return
    {
        evasion = self.fEvasion,
    }
end

function modifier_dragon_knight_dragon_blood_custom:HandleCustomTransmitterData(data)
    if data.evasion ~= nil then
        self.fEvasion = tonumber(data.evasion)
    end
end

function modifier_dragon_knight_dragon_blood_custom:InvokeBonus()
    if IsServer() == true then
        self.fEvasion = self.evasion

        self:SendBuffRefreshToClients()
    end
end

function modifier_dragon_knight_dragon_blood_custom:OnCreated(event)
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    self.parent = self:GetParent()

    self.isPoison = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_green")
    self.isFire = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_red")
    self.isIce = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_blue")
    self.isBlack = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_black")

    self.poisonDuration = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_duration")

    self.fireShieldMod = "modifier_dragon_knight_dragon_blood_custom_fire_shield"

    self.accountID = PlayerResource:GetSteamAccountID(self.parent:GetPlayerID())

    local abilityName = self:GetName()
    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    self:StartIntervalThink(0.1)
end

function modifier_dragon_knight_dragon_blood_custom:OnRemoved(props)
    if not IsServer() then return end

    local caster = self:GetParent()

    local abilityName = self:GetName()

    _G.PlayerDamageReduction[self.accountID] = _G.PlayerDamageReduction[self.accountID] or {}
    _G.PlayerDamageReduction[self.accountID][abilityName] = _G.PlayerDamageReduction[self.accountID][abilityName] or {}

    _G.PlayerDamageReduction[self.accountID][abilityName] = nil
end

function modifier_dragon_knight_dragon_blood_custom:OnIntervalThink()
    self.isPoison = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_green")
    self.isFire = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_red")
    self.isIce = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_blue")
    self.isBlack = self.parent:HasModifier("modifier_dragon_knight_dragon_form_switch_custom_black")

    if self.isFire then
        if not self.parent:HasModifier(self.fireShieldMod) then
            self.parent:AddNewModifier(self.parent, self:GetAbility(), self.fireShieldMod, {})
        end
    else
        self.parent:RemoveModifierByName(self.fireShieldMod)
    end

    if self.isBlack then
        self.evasion = self:GetAbility():GetSpecialValueFor("black_drake_evasion")
    else
        self.evasion = 0
    end

    local abilityName = self:GetName()
    if self.isIce then
        _G.PlayerDamageReduction[self.accountID][abilityName] = self:GetAbility():GetSpecialValueFor("ice_drake_damage_reduction")
    else
        _G.PlayerDamageReduction[self.accountID][abilityName] = nil
    end

    self:InvokeBonus()
end

function modifier_dragon_knight_dragon_blood_custom:OnAttackLanded(event)
    if not IsServer() then return end

    local parent = self:GetParent()

    if parent ~= event.target or parent == event.attacker then return end

    local attacker = event.attacker

    if self.isPoison then
        attacker:AddNewModifier(parent, self:GetAbility(), "modifier_dragon_knight_dragon_blood_custom_poison_debuff", {
            duration = self.poisonDuration
        })
    end
end
--------------
function modifier_dragon_knight_dragon_blood_custom_poison_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT 
    }
end

function modifier_dragon_knight_dragon_blood_custom_poison_debuff:OnCreated()
    if not IsServer() then return end

    self.damageTable = {
        attacker = self:GetCaster(),
        victim = self:GetParent(),
        damage = self:GetAbility():GetSpecialValueFor("poison_drake_debuff_damage") + (self:GetCaster():GetStrength()*(self:GetAbility():GetSpecialValueFor("str_to_damage")/100)),
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = self:GetAbility()
    }

    self:StartIntervalThink(1.0)
end

function modifier_dragon_knight_dragon_blood_custom_poison_debuff:OnIntervalThink()
    ApplyDamage(self.damageTable)
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, self:GetParent(), self.damageTable.damage, nil)
end

function modifier_dragon_knight_dragon_blood_custom_poison_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("poison_drake_debuff_move_slow")
end

function modifier_dragon_knight_dragon_blood_custom_poison_debuff:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("poison_drake_debuff_attack_slow")
end

function modifier_dragon_knight_dragon_blood_custom_poison_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_poison_viper.vpcf"
end
----------
function modifier_dragon_knight_dragon_blood_custom_fire_shield:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()

    self.effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl(self.effect_cast, 1, parent:GetAbsOrigin())

    EmitSoundOn("Hero_EmberSpirit.FlameGuard.Cast", parent)
    EmitSoundOn("Hero_EmberSpirit.FlameGuard.Loop", parent)
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:OnRemoved()
    if not IsServer() then return end

    local parent = self:GetParent()

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end

    StopSoundOn("Hero_EmberSpirit.FlameGuard.Loop", parent)
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:IsAura()
  return true
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("fire_drake_radius")
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield:GetModifierAura()
    return "modifier_dragon_knight_dragon_blood_custom_fire_shield_aura"
end
------------
function modifier_dragon_knight_dragon_blood_custom_fire_shield_aura:OnCreated()
    if not IsServer() then return end

    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local interval = ability:GetSpecialValueFor("fire_drake_interval")
    local damage = (ability:GetSpecialValueFor("fire_drake_damage") + (caster:GetStrength()*(ability:GetSpecialValueFor("str_to_damage")/100))) * interval

    self.damageTable = {
        attacker = caster,
        victim = parent,
        damage = damage,
        damage_type = DAMAGE_TYPE_MAGICAL,
        ability = ability
    }

    self.effect_cast = ParticleManager:CreateParticle( "particles/items2_fx/radiance.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        0,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControlEnt(
        self.effect_cast,
        1,
        parent,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        parent:GetAbsOrigin(), -- unknown
        true -- unknown, true
    )
    ParticleManager:SetParticleControl(self.effect_cast, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.effect_cast, 1, parent:GetAbsOrigin())

    self:StartIntervalThink(interval)
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield_aura:OnIntervalThink()
    ApplyDamage(self.damageTable)
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield_aura:OnRemoved()
    if not IsServer() then return end

    if self.effect_cast ~= nil then
        ParticleManager:DestroyParticle(self.effect_cast, false)
        ParticleManager:ReleaseParticleIndex(self.effect_cast)
    end
end

function modifier_dragon_knight_dragon_blood_custom_fire_shield_aura:GetStatusEffectName()
    return "particles/status_fx/status_effect_burn.vpcf"
end