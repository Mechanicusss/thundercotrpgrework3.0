LinkLuaModifier("modifier_axe_berserkers_call_custom", "heroes/hero_axe/axe_berserkers_call_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_active_buff", "heroes/hero_axe/axe_berserkers_call_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_active_debuff", "heroes/hero_axe/axe_berserkers_call_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_aura", "heroes/hero_axe/axe_berserkers_call_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_berserkers_call_custom_aura_self", "heroes/hero_axe/axe_berserkers_call_custom", LUA_MODIFIER_MOTION_NONE)

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

local ItemBaseClassDebuff = {
    IsPurgable = function(self) return false end,
    RemoveOnDeath = function(self) return true end,
    IsHidden = function(self) return false end,
    IsStackable = function(self) return false end,
    IsDebuff = function(self) return true end,
}

axe_berserkers_call_custom = class(ItemBaseClass)
modifier_axe_berserkers_call_custom = class(axe_berserkers_call_custom)
modifier_axe_berserkers_call_custom_active_buff = class(ItemBaseClassBuff)
modifier_axe_berserkers_call_custom_active_debuff = class(ItemBaseClassDebuff)
modifier_axe_berserkers_call_custom_aura = class(ItemBaseClassDebuff)
modifier_axe_berserkers_call_custom_aura_self = class(ItemBaseClassBuff)
-------------
function axe_berserkers_call_custom:GetIntrinsicModifierName()
    return "modifier_axe_berserkers_call_custom"
end


function axe_berserkers_call_custom:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function axe_berserkers_call_custom:OnSpellStart()
    if not IsServer() then return end

    local caster = self:GetCaster()

    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    caster:AddNewModifier(caster, self, "modifier_axe_berserkers_call_custom_active_buff", {
        duration = duration
    })

    local victims = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil,
            radius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_CLOSEST, false)

    for _,victim in ipairs(victims) do
        if not victim:IsAlive() then break end

        victim:AddNewModifier(caster, self, "modifier_axe_berserkers_call_custom_active_debuff", {
            duration = duration
        })
    end

    EmitSoundOn("Hero_Axe.Berserkers_Call", caster)

    self:PlayEffects()
end

function axe_berserkers_call_custom:PlayEffects()
    -- Get Resources
    local particle_cast = "particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf"

    -- Create Particle
    local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
    ParticleManager:SetParticleControlEnt(
        effect_cast,
        1,
        self:GetCaster(),
        PATTACH_POINT_FOLLOW,
        "attach_mouth",
        Vector(0,0,0), -- unknown
        true -- unknown, true
    )
    ParticleManager:ReleaseParticleIndex( effect_cast )
end
----
function modifier_axe_berserkers_call_custom_active_debuff:OnCreated()
    if not IsServer() then return end

    self:StartIntervalThink(0.1)
end

function modifier_axe_berserkers_call_custom_active_debuff:OnIntervalThink()
    self:GetParent():SetForceAttackTarget(self:GetCaster())
end

function modifier_axe_berserkers_call_custom_active_debuff:OnRemoved()
    local parent = self:GetParent()
    if parent == nil or not parent then return end
    if type(parent) == nil or type(parent) == "nil" then return end
    if parent:IsNull() then return end
    if parent:IsAlive() == nil then return end

    parent:SetForceAttackTarget(nil)
end

function modifier_axe_berserkers_call_custom_active_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_beserkers_call.vpcf"
end
-----
function modifier_axe_berserkers_call_custom_active_buff:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    }

    return funcs
end

function modifier_axe_berserkers_call_custom_active_buff:OnCreated()
    self:SetHasCustomTransmitterData(true)

    if not IsServer() then return end

    local ability = self:GetAbility()
    local parent = self:GetParent()

    self.armor = parent:GetPhysicalArmorValue(false) * (ability:GetSpecialValueFor("active_bonus_armor_pct")/100)

    self:InvokeBonus()
end

function modifier_axe_berserkers_call_custom_active_buff:GetModifierPhysicalArmorBonus()
    return self.fArmor
end

function modifier_axe_berserkers_call_custom_active_buff:AddCustomTransmitterData()
    return
    {
        armor = self.fArmor,
    }
end

function modifier_axe_berserkers_call_custom_active_buff:HandleCustomTransmitterData(data)
    if data.armor ~= nil then
        self.fArmor = tonumber(data.armor)
    end
end

function modifier_axe_berserkers_call_custom_active_buff:InvokeBonus()
    if IsServer() == true then
        self.fArmor = self.armor

        self:SendBuffRefreshToClients()
    end
end
-----
function modifier_axe_berserkers_call_custom:IsAura()
  if self:GetCaster():IsIllusion() then return false end
  return true
end

function modifier_axe_berserkers_call_custom:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_axe_berserkers_call_custom:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_axe_berserkers_call_custom:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_axe_berserkers_call_custom:GetModifierAura()
    return "modifier_axe_berserkers_call_custom_aura"
end

function modifier_axe_berserkers_call_custom:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
end

function modifier_axe_berserkers_call_custom:GetAuraEntityReject(target)
    return false
end
---------
function modifier_axe_berserkers_call_custom_aura:OnCreated()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local buff = caster:FindModifierByName("modifier_axe_berserkers_call_custom_aura_self")
    if not buff then
        buff = caster:AddNewModifier(caster, ability, "modifier_axe_berserkers_call_custom_aura_self", {})
    end

    if buff then
        buff:IncrementStackCount()
    end
end

function modifier_axe_berserkers_call_custom_aura:OnDestroy()
    if not IsServer() then return end

    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    local buff = caster:FindModifierByName("modifier_axe_berserkers_call_custom_aura_self")
    if buff then
        buff:DecrementStackCount()
        if buff:GetStackCount() < 1 then
            buff:Destroy()
        end
    end
end
-------
function modifier_axe_berserkers_call_custom_aura_self:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }

    return funcs
end

function modifier_axe_berserkers_call_custom_aura_self:GetModifierPhysicalArmorBonus()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_axe_berserkers_call_custom_aura_self:GetModifierTotalDamageOutgoing_Percentage()
    return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
end